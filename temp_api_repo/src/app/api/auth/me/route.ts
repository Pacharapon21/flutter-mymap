import { NextRequest, NextResponse } from "next/server";
import { getAuthUser } from "@/lib/auth";
import { users } from "@/db/schema";
import { eq } from "drizzle-orm";
import { db } from "@/db";

export async function GET(request: NextRequest) {
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

    const [user] = await db
      .select({
        id: users.id,
        email: users.email,
        name: users.name,
        bio: users.bio,
        profileImage: users.profileImage,
        coverImage: users.coverImage,
        socialLinks: users.socialLinks,
        isVerified: users.isVerified,
        createdAt: users.createdAt,
        updatedAt: users.updatedAt,
      })
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

    return NextResponse.json(
      {
        message: "User found",
        user: user,
      },
      {
        status: 200,
      },
    );
  } catch (error) {
    console.error("Get me error:", error);
    return NextResponse.json(
      {
        message: "Failed to get user",
      },
      {
        status: 500,
      },
    );
  }
}
