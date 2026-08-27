import { SignJWT, jwtVerify, JWTPayload } from "jose";

function getJwtSecretKey() {
  const secret = process.env.JWT_SECRET
  if (!secret) {
    throw new Error("JWT_SECRET is not defined")
  }
  return new TextEncoder().encode(secret);
}

export async function signJWT(payload: Record<string, unknown>, expiresIn: string = "7d"): Promise<string> {
  const secretKey = getJwtSecretKey();

  return new SignJWT(payload)
    .setProtectedHeader({ alg: "HS256" })
    .setIssuedAt()
    .setExpirationTime(expiresIn)
    .sign(secretKey);
}

export async function verifyJWT<T = JWTPayload>(token: string): Promise<T | null> {
  try {
    const secretKey = getJwtSecretKey();
    const { payload } = await jwtVerify(token, secretKey);
    return payload as T;
  } catch (error) {
    // ถ้า Token ปลอมแปลง, ผิดรูปแบบ หรือหมดอายุ จะตกมาที่นี่
    console.error("JWT Verification failed:", error);
    return null;
  }
}
