import { NextResponse } from "next/server";
import { db } from "@/db";
import { users } from "@/db/schema";

export async function GET() {
    try {
        const result = await db.select().from(users);
        return NextResponse.json({
            message: "database connection success",
            users: result,
            
        }, {
            status: 200
        });


    } catch (error) {
        console.error(error);

        return NextResponse.json({
            message: "database not connection",
        },
            { status: 500 }
        )
    }
}