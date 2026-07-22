# Build trên Cloud — Dành cho máy yếu (3.5GB RAM, Snapdragon 425)

> Điện thoại của bạn KHÔNG THỂ build APK được. Dùng 1 trong 3 cách dưới đây.

---

## 🏆 Cách 1: GitHub Actions (TỐT NHẤT — Khuyến nghị)

**Ưu điểm:**
- ✅ Miễn phí vô hạn (public repo)
- ✅ Không tốn RAM/CPU của bạn
- ✅ Build tự động, chỉ cần bấm 1 nút
- ✅ Tải APK về trong 2 phút

### Các bước:

**Bước 1:** Tạo repository mới trên GitHub (ví dụ: `motioncut-app`)

**Bước 2:** Upload toàn bộ code trong thư mục `motioncut_pro_v2` lên repo đó
```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/motioncut-app.git
git push -u origin main
```

**Bước 3:** Vào GitHub web → tab **Actions** → chọn workflow **Build APK** → bấm **Run workflow**

**Bước 4:** Đợi ~5 phút → vào tab **Actions** → click vào run mới nhất → kéo xuống phần **Artifacts** → tải `motioncut-apk.zip` về

**Bước 5:** Giải nén ZIP, cài APK vào điện thoại

> 💡 **Mẹo:** Mỗi lần sửa code và push lên GitHub, Actions sẽ tự động build APK mới.

---

## 💻 Cách 2: GitHub Codespaces (Build trực tiếp trên trình duyệt)

**Ưu điểm:**
- ✅ Không cần cài gì trên máy tính
- ✅ Chạy trên trình duyệt
- ✅ Free 120 giờ/tháng

**Nhược điểm:**
- ⚠️ Setup lần đầu mất ~10 phút
- ⚠️ Cần biết dùng terminal Linux cơ bản

### Các bước:

**Bước 1:** Upload code lên GitHub repo (như Cách 1)

**Bước 2:** Trên GitHub web, bấm nút **Code** → tab **Codespaces** → **Create codespace on main**

**Bước 3:** Đợi Codespaces khởi động (~2 phút). Terminal sẽ tự chạy setup.

**Bước 4:** Trong terminal của Codespaces, chạy:
```bash
bash scripts/build_apk.sh
```

**Bước 5:** Sau khi build xong, chạy:
```bash
cp build/app/outputs/flutter-apk/app-release.apk motioncut.apk
```

**Bước 6:** File `motioncut.apk` sẽ xuất hiện trong file explorer bên trái. Right-click → **Download** về máy tính rồi chuyển sang điện thoại.

---

## 📊 Cách 3: Google Colab (KHÔNG KHUYẾN KHÍCH)

> Colab không phù hợp build Flutter vì:
> - Không có Android SDK
> - Dễ bị timeout
> - Khó lưu file APK

**Chỉ dùng nếu 2 cách trên không được.**

```python
# Trong cell Colab:
!apt-get update -qq
!apt-get install -y -qq git curl unzip xz-utils
!git clone https://github.com/flutter/flutter.git -b stable /opt/flutter
import os
os.environ['PATH'] += ':/opt/flutter/bin'
!flutter doctor
```

---

## ⚠️ Lưu ý về điện thoại của bạn (Snapdragon 425 + 3.5GB RAM)

App này có thể **chạy chậm** hoặc **crash** trên máy bạn vì:
- Video player + FFmpeg decode tốn RAM
- Nhiều effect đồng thời tốn GPU
- Preview canvas render nhiều layer

**Khuyến nghị khi dùng:**
- Chỉ edit video ngắn (< 30 giây)
- Giảm preview resolution xuống 720p
- Không dùng quá 3 layer cùng lúc
- Tắt effect nặng (chromatic aberration, motion blur) khi preview

---

## 📱 Cách cài APK vào điện thoại

1. Copy file APK vào điện thoại (qua USB, Zalo, Telegram, Google Drive...)
2. Mở file APK trên điện thoại
3. Nếu báo "Không cho phép cài đặt":
   - Vào **Cài đặt → Bảo mật → Nguồn không xác định** → Bật cho phép
4. Cài đặt và mở app

---

## 🆘 Hỗ trợ

Nếu build lỗi, hãy:
1. Vào tab **Actions** trên GitHub
2. Click vào run bị lỗi
3. Copy log lỗi và gửi cho tôi
