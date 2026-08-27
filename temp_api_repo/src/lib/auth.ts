import { NextRequest } from "next/server";
import { verifyJWT } from "./jwt";

// ใน src/lib/jwt.ts หรือ src/lib/auth.ts
export interface AuthUser {
  id: number;
  email: string;
  name: string;
}

export async function getAuthUser(request: NextRequest): Promise<AuthUser | null> {
  // 1. ดึงจาก Cookie
  let token = request.cookies.get("auth-token")?.value;

  // 2. ถ้าไม่มีใน Cookie ให้ดึงจาก Authorization Header
  if (!token) {
    const authHeader = request.headers.get("Authorization") || request.headers.get("authorization");
    if (authHeader && authHeader.startsWith("Bearer ")) {
      token = authHeader.substring(7);
    }
  }

  if (!token) return null;

  // 3. ตรวจสอบ JWT
  const payload = await verifyJWT<AuthUser>(token);
  return payload;
}
