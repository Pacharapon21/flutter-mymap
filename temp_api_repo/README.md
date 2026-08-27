# 📍 Where Am I - Backend API

ระบบ Backend API สำหรับแอปพลิเคชันบันทึกพิกัดและเช็คอินสถานที่ (**Where Am I**) พร้อมระบบยืนยันตัวตนผ่าน OTP ทางอีเมล และการอัปโหลดรูปภาพสถานที่ขึ้น Cloud Storage รองรับการทำงานร่วมกับ **Flutter (iOS & Android)** และ Web Applications อย่างสมบูรณ์

---

## 🚀 Tech Stack

- **Framework**: [Next.js 16 (App Router)](https://nextjs.org/) & [TypeScript](https://www.typescriptlang.org/)
- **Database**: [Neon PostgreSQL](https://neon.tech/) (Serverless Postgres)
- **ORM**: [Drizzle ORM](https://orm.drizzle.team/)
- **Authentication**: JWT (`jose`), Password Hashing (`argon2`), HTTP-Only Cookies & Bearer Tokens
- **Email Service**: [Resend](https://resend.com/) (ส่งรหัส OTP 6 หลัก สำหรับยืนยันอีเมล)
- **Cloud Storage**: [Google Cloud Storage (GCS)](https://cloud.google.com/storage) (สำหรับจัดเก็บรูปภาพสถานที่เช็คอิน)

---

## ⚙️ การตั้งค่า Environment Variables (`.env`)

สร้างหรือแก้ไขไฟล์ `.env` ใน Root Directory ของโปรเจกต์:

```env
# 1. Neon PostgreSQL Database URL
DATABASE_URL="postgresql://username:password@ep-xxxx.ap-southeast-1.aws.neon.tech/where_am_i?sslmode=require"

# 2. JWT Secret Key (สำหรับ Sign & Verify Token)
JWT_SECRET=your_super_secret_jwt_key_here

# 3. Google Cloud Storage Configuration (สำหรับรูปภาพ Check-in)
GCS_BUCKET_NAME="where_am_i"
GCS_PROJECT_ID="your-gcp-project-id"
GCS_CLIENT_EMAIL="your-service-account@your-project.iam.gserviceaccount.com"
GCS_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

# 4. Resend Email Configuration (สำหรับส่งรหัส OTP)
RESEND_API_KEY=re_xxxxxxxxxxxxxxxxxxxxxxxxxx
EMAIL_FROM="Where Am I <onboarding@resend.dev>"
```

---

## 💻 การติดตั้งและเริ่มรันเซิร์ฟเวอร์

```bash
# 1. ติดตั้ง Dependencies
npm install

# 2. ทำการ Push Database Schema ไปยัง Neon DB
npm run db:push

# 3. รันเซิร์ฟเวอร์ Development (Port 3000)
npm run dev
```

---

## 📖 API Documentation

Base URL: `http://localhost:3000` (หรือ Production Domain)

### 🔐 1. Authentication APIs (`/api/auth/*`)

#### 1.1 สมัครสมาชิก (Register)
* **Endpoint**: `POST /api/auth/register`
* **Content-Type**: `application/json`
* **Request Body**:
  ```json
  {
    "fname": "Somchai",
    "lname": "Jaidee",
    "email": "somchai@example.com",
    "password": "password1234"
  }
  ```
  *(สามารถส่งเป็น `"name": "Somchai Jaidee"` แทน `fname`+`lname` ได้)*
* **Response (201 Created)**:
  ```json
  {
    "message": "User registered successfully. Please verify your email with the OTP sent to your inbox.",
    "user": {
      "id": 1,
      "name": "Somchai Jaidee",
      "email": "somchai@example.com",
      "isVerified": false
    },
    "requiresVerification": true
  }
  ```

---

#### 1.2 ยืนยันรหัส OTP (Verify OTP)
* **Endpoint**: `POST /api/auth/verify-otp`
* **Content-Type**: `application/json`
* **Request Body**:
  ```json
  {
    "email": "somchai@example.com",
    "otp": "723871"
  }
  ```
* **Response (200 OK)**:
  ```json
  {
    "message": "Email verified successfully",
    "user": {
      "id": 1,
      "name": "Somchai Jaidee",
      "email": "somchai@example.com",
      "isVerified": true
    },
    "token": "eyJhbGciOiJIUzI1NiJ9..."
  }
  ```

---

#### 1.3 ขอรหัส OTP ใหม่ (Resend OTP)
* **Endpoint**: `POST /api/auth/resend-otp`
* **Content-Type**: `application/json`
* **Request Body**:
  ```json
  {
    "email": "somchai@example.com"
  }
  ```
* **Response (200 OK)**:
  ```json
  {
    "message": "New OTP has been sent to your email"
  }
  ```

---

#### 1.4 เข้าสู่ระบบ (Login)
* **Endpoint**: `POST /api/auth/login`
* **Content-Type**: `application/json`
* **Request Body**:
  ```json
  {
    "email": "somchai@example.com",
    "password": "password1234"
  }
  ```
* **Response (200 OK)**:
  ```json
  {
    "message": "Logged in successfully",
    "user": {
      "id": 1,
      "email": "somchai@example.com",
      "name": "Somchai Jaidee",
      "isVerified": true
    },
    "token": "eyJhbGciOiJIUzI1NiJ9..."
  }
  ```

---

#### 1.5 ดึงข้อมูลผู้ใช้ปัจจุบัน (Get Profile)
* **Endpoint**: `GET /api/auth/me`
* **Headers**: `Authorization: Bearer <TOKEN>`
* **Response (200 OK)**:
  ```json
  {
    "message": "User found",
    "user": {
      "id": 1,
      "email": "somchai@example.com",
      "name": "Somchai Jaidee",
      "isVerified": true,
      "profileImage": null,
      "coverImage": null,
      "bio": null
    }
  }
  ```

---

#### 1.6 เปลี่ยนรหัสผ่าน (Change Password)
* **Endpoint**: `PUT /api/auth/change-password`
* **Headers**: `Authorization: Bearer <TOKEN>`
* **Request Body**:
  ```json
  {
    "oldPassword": "password1234",
    "newPassword": "newpassword5678"
  }
  ```

---

#### 1.7 ออกจากระบบ (Logout)
* **Endpoint**: `POST /api/auth/logout`

---

### 📍 2. Check-in APIs (`/api/checking`)

#### 2.1 บันทึกการ Check-in พร้อมรูปภาพ (Create Check-in)
* **Endpoint**: `POST /api/checking`
* **Headers**: `Authorization: Bearer <TOKEN>`
* **Content-Type**: `multipart/form-data`
* **Form Fields**:
  - `lat` *(number, required)*: ละติจูด เช่น `13.7469`
  - `lng` *(number, required)*: ลองจิจูด เช่น `100.5349`
  - `locationName` *(string, optional)*: ชื่อสถานที่ เช่น `"สยามพารากอน"`
  - `address` *(string, optional)*: ที่อยู่สถานที่
  - `accuracy` *(number, optional)*: ความแม่นยำของ GPS (เมตร)
  - `description` *(string, optional)*: รายละเอียด/บันทึกความทรงจำ
  - `image` *(File, optional)*: ไฟล์รูปภาพ (.jpg, .png, .webp)
* **Response (201 Created)**:
  ```json
  {
    "message": "Check-in created successfully",
    "checkin": {
      "id": 4,
      "userId": 1,
      "lat": 13.7469,
      "lng": 100.5349,
      "locationName": "สยามพารากอน",
      "address": "ถ.พระรามที่ ๑ แขวงปทุมวัน เขตปทุมวัน กรุงเทพมหานคร",
      "accuracy": 15.5,
      "description": "มาเดินเล่นวันหยุด",
      "imageUrl": "https://storage.googleapis.com/where_am_i/checkins/1_1787058244392_79gjqv.jpg",
      "createdAt": "2026-08-18T13:04:05.304Z"
    }
  }
  ```

---

#### 2.2 ดึงรายการ Check-in (Get Check-ins)
* **Endpoint**: `GET /api/checking`
* **Query Parameters**:
  - `my=true` *(optional)*: ดึงเฉพาะ Check-in ของตนเอง (ต้องแนบ Bearer Token)
  - `limit=50` *(optional)*: จำนวนรายการสูงสุด (ค่าเริ่มต้น: 100)
* **Response (200 OK)**:
  ```json
  {
    "message": "Check-ins retrieved successfully",
    "checkins": [
      {
        "id": 4,
        "lat": 13.7469,
        "lng": 100.5349,
        "locationName": "สยามพารากอน",
        "address": "กรุงเทพมหานคร",
        "description": "มาเดินเล่นวันหยุด",
        "imageUrl": "https://storage.googleapis.com/where_am_i/checkins/1_1787058244392_79gjqv.jpg",
        "createdAt": "2026-08-18T13:04:05.304Z",
        "user": {
          "id": 1,
          "name": "Somchai Jaidee",
          "profileImage": null
        }
      }
    ]
  }
  ```

---

#### 2.3 แก้ไข Check-in (Update Check-in)
* **Endpoint**: `PUT /api/checking`
* **Headers**: `Authorization: Bearer <TOKEN>`
* **Request Body (JSON หรือ Form-Data)**:
  ```json
  {
    "id": 4,
    "locationName": "สยามพารากอน ชั้น G",
    "description": "แก้ไขข้อความเช็คอิน"
  }
  ```

---

#### 2.4 ลบ Check-in (Delete Check-in)
* **Endpoint**: `DELETE /api/checking?id=4`
* **Headers**: `Authorization: Bearer <TOKEN>`

---

## 📱 วิธีเชื่อมต่อและใช้งานกับ Flutter

### 1. แพ็กเกจที่แนะนำสำหรับ Flutter (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0           # สำหรับเรียกใช้งาน REST API
  geolocator: ^11.0.0     # สำหรับดึงพิกัด GPS ละติจูด/ลองจิจูด
  image_picker: ^1.0.7   # สำหรับถ่ายรูปหรือเลือกรูปจากแกลเลอรี
  flutter_map: ^6.1.0    # แผนที่ OpenStreetMap ฟรี 100%
  latlong2: ^0.9.0       # สำหรับจัดการพิกัด LatLng
```

---

### 2. ตัวอย่าง Service ใน Flutter สำหรับ Check-in พร้อมรูป

```dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class CheckinService {
  final String baseUrl = "http://10.0.2.2:3000"; // สำหรับ Android Emulator (ถ้า iOS ใช้ http://localhost:3000)

  // ฟังก์ชัน Check-in พร้อมพิกัด GPS และรูปถ่าย
  Future<void> submitCheckin({
    required String token,
    required String locationName,
    required String description,
    File? imageFile,
  }) async {
    // 1. ดึงพิกัด GPS ปัจจุบัน
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // 2. เตรียม Multipart Request
    var uri = Uri.parse('$baseUrl/api/checking');
    var request = http.MultipartRequest('POST', uri);

    // 3. แนบ Auth Token ใน Header
    request.headers['Authorization'] = 'Bearer $token';

    // 4. แนบข้อมูลพิกัดและข้อความ
    request.fields['lat'] = position.latitude.toString();
    request.fields['lng'] = position.longitude.toString();
    request.fields['accuracy'] = position.accuracy.toString();
    request.fields['locationName'] = locationName;
    request.fields['description'] = description;

    // 5. แนบไฟล์รูปภาพ
    if (imageFile != null && await imageFile.exists()) {
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
    }

    // 6. ส่งข้อมูลไปยัง Backend
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      print("✅ เช็คอินสำเร็จ: ${response.body}");
    } else {
      print("❌ เกิดข้อผิดพลาด (${response.statusCode}): ${response.body}");
    }
  }
}
```

---

## 🗺️ แนะนำ Map APIs ที่น่าใช้ร่วมกับ Backend

เนื่องจาก Backend จัดเก็บพิกัดเป็นมาตรฐาน **`lat` (Latitude)** และ **`lng` (Longitude)** จึงสามารถนำไปแสดงผลบนแผนที่ใดๆ ได้ทันที:

### 1. 🥇 OpenStreetMap (`flutter_map`) — *แนะนำที่สุด ⭐⭐⭐⭐⭐*
- **จุดเด่น**: **ฟรี 100%** ไม่มีค่าใช้จ่าย ไม่ต้องผูกบัตรเครดิต และไม่ต้องสร้าง API Key
- **ตัวอย่างโค้ดปักหมุดใน Flutter**:
  ```dart
  FlutterMap(
    options: MapOptions(
      initialCenter: LatLng(checkin.lat, checkin.lng),
      initialZoom: 15.0,
    ),
    children: [
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      ),
      MarkerLayer(
        markers: checkinList.map((item) => Marker(
          point: LatLng(item.lat, item.lng),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () => showCheckinDialog(item),
            child: Icon(Icons.location_on, color: Colors.red, size: 40),
          ),
        )).toList(),
      ),
    ],
  )
  ```

---

### 2. 🥈 Google Maps Platform (`google_maps_flutter`)
- **จุดเด่น**: ข้อมูลในไทยละเอียดที่สุด มีระบบค้นหาสถานที่ (Google Places API) และแปลงพิกัดเป็นชื่อภาษาไทย (Geocoding API)
- **ค่าใช้จ่าย**: เครดิตฟรี $200 ต่อเดือน (ต้องใช้ API Key)

---

### 3. 🥉 Mapbox (`mapbox_maps_flutter`)
- **จุดเด่น**: ดีไซน์แผนที่สวยงามและทันสมัย ปรับแต่งสีและเลเยอร์ 3D ได้อิสระ
- **ค่าใช้จ่าย**: ฟรี 50,000 Map Loads/เดือน

---

## 📄 License
MIT License
