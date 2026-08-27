import { db } from "@/db";
import { users, verificationTokens } from "@/db/schema";
import { and, eq, gt } from "drizzle-orm";
import { NextResponse } from "next/server";
import { signJWT } from "@/lib/jwt";

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const { email, otp } = body;

    if (!email || !otp || typeof email !== "string" || typeof otp !== "string") {
      return NextResponse.json(
        {
          message: "Email and OTP are required",
        },
        {
          status: 400,
        },
      );
    }

    const normalizedEmail = email.toLowerCase().trim();
    const cleanOtp = otp.trim();

    // 1. Find valid and unexpired OTP
    const [tokenRecord] = await db
      .select()
      .from(verificationTokens)
      .where(
        and(
          eq(verificationTokens.email, normalizedEmail),
          eq(verificationTokens.otp, cleanOtp),
          gt(verificationTokens.expiresAt, new Date()),
        ),
      )
      .limit(1);

    if (!tokenRecord) {
      return NextResponse.json(
        {
          message: "Invalid or expired OTP code",
        },
        {
          status: 400,
        },
      );
    }

    // 2. Update user isVerified = true
    const [user] = await db
      .update(users)
      .set({
        isVerified: true,
        updatedAt: new Date(),
      })
      .where(eq(users.email, normalizedEmail))
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

    if (!user) {
      return NextResponse.json(
        {
          message: "User not found",
        },
        {
          status: 404,
        },
      );
    }

    // 3. Delete used tokens
    await db
      .delete(verificationTokens)
      .where(eq(verificationTokens.email, normalizedEmail));

    // 4. Issue JWT
    const jwtToken = await signJWT({
      id: user.id,
      email: user.email,
      name: user.name,
    });

    const response = NextResponse.json(
      {
        message: "Email verified successfully",
        user: user,
        token: jwtToken,
      },
      {
        status: 200,
      },
    );

    response.cookies.set({
      name: "auth-token",
      value: jwtToken,
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "lax",
      maxAge: 60 * 60 * 24 * 7,
      path: "/",
    });

    return response;
  } catch (error) {
    console.error("Verify OTP error:", error);
    return NextResponse.json(
      {
        message: "Failed to verify OTP",
      },
      {
        status: 500,
      },
    );
  }
}
