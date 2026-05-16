# meta_glass_ai
An iOS app that uses Apple OCR to detect text encountered by meta ai glasses

Here’s the full end‑to‑end flow to test the app:

1. Build & run on a real iPhone
• Needs Bluetooth + External Accessory; simulator won’t work for glasses.
• Ensure Signing & Capabilities has your Team selected.

2. Open Meta AI app and sign in
• Make sure your glasses are paired in the Meta AI app.
• Complete any device permissions there (camera permission is required for devices to show up).

3. Register from your app
• Launch your app.
• Tap Register.
• Meta AI app should open and confirm the registration.

4. Return to your app
• The app should update Registration status.
• Devices should appear once camera permission is granted in Meta AI.

5. Request camera permission
• Tap Request Camera Permission in your app.
• Confirm in Meta AI app if prompted.

6. Start streaming
• Tap Start Stream.
• You should see the live preview.
• OCR text should start populating under “Detected Text.”

7. Capture a photo (optional)
• Tap Capture Photo.
• Tap Save Photo to store it in Photos (you’ll get the system prompt).

Troubleshooting
• Devices empty: ensure Meta AI granted camera permission.
• Stream won’t start: re‑register, check Bluetooth and that the glasses are connected in Meta AI.
• No callback: confirm CFBundle​URLSchemes and MWDAT​.​App​Link​URLScheme match.
