import { db } from "@/db";
import { users, verificationTokens } from "@/db/schema";
import { eq } from "drizzle-orm";
import { NextResponse } from "next/server";
import { sendOtpEmail } from "@/lib/mail";

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const { email } = body;

    if (!email || typeof email !== "string") {
      return NextResponse.json(
        {
          message: "Email is required",
        },
        {
          status: 400,
        },
      );
    }

    const normalizedEmail = email.toLowerCase().trim();

    // 1. Check if user exists
    const [user] = await db
      .select({ id: users.id, isVerified: users.isVerified })
      .from(users)
      .where(eq(users.email, normalizedEmail))
      .limit(1);

    if (!user) {
      return NextResponse.json(
        {
          message: "User not found with this email",
        },
        {
          status: 404,
        },
      );
    }

    if (user.isVerified) {
      return NextResponse.json(
        {
          message: "This email is already verified",
        },
        {
          status: 400,
        },
      );
    }

    // 2. Generate new OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes

    // Delete old tokens
    await db
      .delete(verificationTokens)
      .where(eq(verificationTokens.email, normalizedEmail));

    // Save new token
    await db.insert(verificationTokens).values({
      email: normalizedEmail,
      otp: otp,
      expiresAt: expiresAt,
    });

    // 3. Send email with Resend
    try {
      await sendOtpEmail(normalizedEmail, otp);
    } catch (mailError) {
      console.error("Failed to resend OTP email via Resend:", mailError);
    }

    return NextResponse.json(
      {
        message: "New OTP has been sent to your email",
      },
      {
        status: 200,
      },
    );
  } catch (error) {
    console.error("Resend OTP error:", error);
    return NextResponse.json(
      {
        message: "Failed to resend OTP",
      },
      {
        status: 500,
      },
    );
  }
}
