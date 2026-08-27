import { db } from "@/db";
import { users } from "@/db/schema";
import { getAuthUser } from "@/lib/auth";
import argon2 from "argon2";
import { NextRequest, NextResponse } from "next/server";
import { eq } from "drizzle-orm";

export async function PUT(request: NextRequest) {
  try {
    const payload = await getAuthUser(request);
    if (!payload || !payload.id) {
      return NextResponse.json(
        {
          message: "Unauthorized",
        },
        {
          status: 401,
        },
      );
    }

    const body = await request.json();
    const { oldPassword, newPassword } = body;

    if (
      typeof oldPassword !== "string" ||
      typeof newPassword !== "string" ||
      !oldPassword.trim() ||
      !newPassword.trim()
    ) {
      return NextResponse.json(
        {
          message: "Old password and new password are required",
        },
        {
          status: 400,
        },
      );
    }

    if (oldPassword.trim() === newPassword.trim()) {
      return NextResponse.json(
        {
          message: "Old password and new password must be different",
        },
        {
          status: 400,
        },
      );
    }

    if (newPassword.trim().length < 6) {
      return NextResponse.json(
        {
          message: "Password must be at least 6 characters long",
        },
        {
          status: 400,
        },
      );
    }

    const [user] = await db
      .select({ id: users.id, password: users.password })
      .from(users)
      .where(eq(users.id, payload.id))
      .limit(1);

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

    const isOldPasswordValid = await argon2.verify(user.password, oldPassword);
    if (!isOldPasswordValid) {
      return NextResponse.json(
        {
          message: "Invalid old password",
        },
        {
          status: 400,
        },
      );
    }

    const hashPassword = await argon2.hash(newPassword);

    const [updatedUser] = await db
      .update(users)
      .set({
        password: hashPassword,
        updatedAt: new Date(),
      })
      .where(eq(users.id, payload.id))
      .returning({
        id: users.id,
        email: users.email,
        name: users.name,
        profileImage: users.profileImage,
        coverImage: users.coverImage,
        bio: users.bio,
      });

    return NextResponse.json(
      {
        message: "Password changed successfully",
        user: updatedUser,
      },
      {
        status: 200,
      },
    );
  } catch (error) {
    console.error("Change password error:", error);
    return NextResponse.json(
      {
        message: "Failed to change password",
      },
      {
        status: 500,
      },
    );
  }
}
