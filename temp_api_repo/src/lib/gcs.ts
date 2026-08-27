import { Storage } from "@google-cloud/storage";
const storage = new Storage({
  projectId: process.env.GCS_PROJECT_ID,
  credentials: {
    client_email: process.env.GCS_CLIENT_EMAIL,
    private_key: process.env.GCS_PRIVATE_KEY?.replace(/\\n/g, "\n"),
  },
});

export const bucket = storage.bucket(process.env.GCS_BUCKET_NAME || "");

export async function uploadToGCS(
  buffer:Buffer,
  filename:string,
  contentType:string
): Promise<string> {

  const file = bucket.file(filename);

  await file.save(buffer, {
    metadata: {
      contentType: contentType,
    },
    resumable: false,
  });

  return `https://storage.googleapis.com/${bucket.name}/${filename}`;





}
