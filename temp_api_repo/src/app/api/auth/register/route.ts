import { db } from "@/db";
import { users, verificationTokens } from "@/db/schema";
import { eq } from "drizzle-orm";
import { NextResponse } from "next/server";
import argon2 from "argon2";
import { sendOtpEmail } from "@/lib/mail";

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const { email, name, fname, lname, password } = body;

    // Support both `name` or `fname` + `lname`
    const displayName = (name || `${fname || ""} ${lname || ""}`).trim();

    if (
      !email ||
      typeof email !== "string" ||
      !password ||
      typeof password !== "string" ||
      !displayName
    ) {
      return NextResponse.json(
        {
          message: "Email, name (or fname and lname), and password are required",
        },
        {
          status: 400,
        },
      );
    }

    const normalizedEmail = email.toLowerCase().trim();

    // Validate email format (accepts any valid email domain)
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(normalizedEmail) || normalizedEmail.length > 255) {
      return NextResponse.json(
        {
          message: "Please provide a valid email address",
        },
        {
          status: 400,
        },
      );
    }

    if (password.length < 6) {
      return NextResponse.json(
        {
          message: "Password must be at least 6 characters long",
        },
        {
          status: 400,
        },
      );
    }

    const existingUser = await db
      .select({ id: users.id, isVerified: users.isVerified })
      .from(users)
      .where(eq(users.email, normalizedEmail))
      .limit(1);

    if (existingUser.length > 0) {
      return NextResponse.json(
        {
          message: "Email already exists",
        },
        {
          status: 409,
        },
      );
    }

    const hashPassword = await argon2.hash(password);

    // 1. Create user with isVerified = false
    const [user] = await db
      .insert(users)
      .values({
        email: normalizedEmail,
        name: displayName,
        password: hashPassword,
        isVerified: false,
      })
      .returning({
        id: users.id,
        name: users.name,
        email: users.email,
        bio: users.bio,
        profileImage: users.profileImage,
        coverImage: users.coverImage,
        socialLinks: users.socialLinks,
        isVerified: users.isVerified,
        createdAt: users.createdAt,
        updatedAt: users.updatedAt,
      });

    // 2. Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes expiration

    // Clean up any old tokens for this email
    await db
      .delete(verificationTokens)
      .where(eq(verificationTokens.email, normalizedEmail));

    // Save token to DB
    await db.insert(verificationTokens).values({
      email: normalizedEmail,
      otp: otp,
      expiresAt: expiresAt,
    });

    // 3. Send email with Resend
    try {
      await sendOtpEmail(normalizedEmail, otp);
    } catch (mailError) {
      console.error("Failed to send OTP email via Resend:", mailError);
      // We don't fail registration completely if Resend key is missing/testing, but log it
    }

    return NextResponse.json(
      {
        message: "User registered successfully. Please verify your email with the OTP sent to your inbox.",
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          isVerified: user.isVerified,
        },
        requiresVerification: true,
      },
      {
        status: 201,
      },
    );
  } catch (error) {
    console.error("Register error:", error);
    return NextResponse.json(
      {
        message: "Failed to register",
      },
      {
        status: 500,
      },
    );
  }
}
