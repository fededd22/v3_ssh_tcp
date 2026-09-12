# SSH SSL/SNI Tunnel Server -- Telegram Bot Admin

خادم نفق SSH يعمل عبر WebSocket/TLS بتمويه SNI، تتم إدارته **بالكامل عبر بوت تلقرام**.
لا توجد أي واجهة ويب أو تسجيل دخول -- البوت هو نقطة التحكم الوحيدة، ويعمل حصريًا مع معرف الأدمن المحدد في `TELEGRAM_ADMIN_CHAT_ID`.

## المزايا

- نفق **SSH** كامل عبر نفس النطاق والمنفذ (TLS + WebSocket Upgrade فقط)، بتمويه SNI (افتراضيًا `youtube.com`).
- بايلود WebSocket جاهز للإرسال مباشرة من البوت.
- تغيير اسم المستخدم/كلمة المرور لحساب SSH مباشرة من تلقرام (بدون إعادة نشر).
- عرض حالة الخادم (تشغيل، القرص، الذاكرة).
- عرض الأجهزة/الاتصالات النشطة حاليًا (`/devices`).
- إدارة مشرفين ثانويين (إضافة/حذف) من داخل تلقرام.
- عرض آخر سجلات التشغيل.
- أي مستخدم آخر غير الأدمن (أو المشرفين الثانويين) يُتجاهل تلقائيًا وبصمت.

حساب SSH واحد مشترك (`SSH_USERNAME`/`SSH_PASSWORD` في `.env`، افتراضيًا `vpsuser`/`vpspass`) --
**غيّر بيانات الاعتماد قبل أي نشر علني**.

**الوصول للبوت مقتصر فعليًا على الأدمن:** أي رسالة أو ضغطة زر من حساب تلقرام غير مطابق
لـ `TELEGRAM_ADMIN_CHAT_ID` (أو أدمن ثانوي مضاف) تُتجاهل بصمت تمامًا -- بدون إرسال أي قائمة
أو بيانات اتصال. تأكد من ضبط `TELEGRAM_ADMIN_CHAT_ID` بمعرف حسابك الصحيح (أرسل `/id` للبوت
من حسابك لمعرفته) قبل النشر.

## التشغيل محليًا

**المتطلبات:** Node.js 22+

1. تثبيت الاعتماديات: `npm install`
2. انسخ `.env.example` إلى `.env` واضبط:
   - `APP_URL` — نطاق الخادم العلني (يُستخدم لبناء بيانات الاتصال)
   - `TELEGRAM_BOT_TOKEN` — توكن بوت تلقرام
   - `TELEGRAM_ADMIN_CHAT_ID` — معرف حساب تلقرام المسموح له وحده بالتحكم
3. تشغيل التطبيق: `npm run dev`
4. من تلقرام: أرسل `/start` للبوت لعرض القائمة الرئيسية.

## النشر عبر Docker

```bash
docker build -t ssh-bot .
docker run -e TELEGRAM_BOT_TOKEN=... -e TELEGRAM_ADMIN_CHAT_ID=... -e APP_URL=https://your-domain.com \
  --ulimit nofile=65536:65536 \
  -p 3000:3000 ssh-bot
```

راجع `Dockerfile` و`docker-compose.yml` لمزيد من التفاصيل.

## النشر على Cloud Run

المشروع متوافق مع Cloud Run: منفذ واحد فقط (`PORT`)، وكل حركة SSH تمر عبر WebSocket على نفس المنفذ.

```bash
gcloud run deploy ssh-bot \
  --source . \
  --region=YOUR_REGION \
  --allow-unauthenticated \
  --min-instances=1 \
  --timeout=3600 \
  --set-env-vars TELEGRAM_BOT_TOKEN=xxx,TELEGRAM_ADMIN_CHAT_ID=xxx,APP_URL=https://your-service-url
```

**ملاحظة تخزين:** ملفات `admin.json`/`settings.json` تُحفظ داخل `DATA_DIR` (افتراضيًا `/app/data`)،
وهو تخزين مؤقت (ephemeral) على Cloud Run -- يُمسح عند إعادة النشر أو تبديل الـ instance.
عرّف `TELEGRAM_ADMIN_CHAT_ID` دائمًا كمتغير بيئة (الكود يعتبره الأولوية) حتى لا تفقد ملكية البوت.
