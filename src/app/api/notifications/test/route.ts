import { NextResponse } from "next/server";

type TestNotificationBody = {
  type: "telegram" | "webhook";
  telegramBotToken?: string;
  telegramChatId?: string;
  webhookUrl?: string;
  webhookSecret?: string;
};

export async function POST(req: Request) {
  try {
    const body = (await req.json()) as TestNotificationBody;

    if (body.type === "telegram") {
      if (!body.telegramBotToken || !body.telegramChatId) {
        return NextResponse.json({ error: "Missing Telegram config" }, { status: 400 });
      }

      const text = [
        "🧪 这是 Telegram 测试消息",
        "",
        "如果你能看到这条消息，说明 Telegram 配置是通的。",
        `时间: ${new Date().toLocaleString('zh-CN', { timeZone: 'Asia/Shanghai' })}`,
      ].join("\n");

      const response = await fetch(`https://api.telegram.org/bot${body.telegramBotToken}/sendMessage`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          chat_id: body.telegramChatId,
          text,
          disable_web_page_preview: true,
        }),
      });

      if (!response.ok) {
        const detail = await response.text();
        return NextResponse.json({ error: "Telegram request failed", detail }, { status: 502 });
      }

      return NextResponse.json({ ok: true });
    }

    if (!body.webhookUrl) {
      return NextResponse.json({ error: "Missing webhook URL" }, { status: 400 });
    }

    const payload = {
      source: "love-app",
      type: "webhook-test",
      occurred_at: new Date().toISOString(),
      message: "这是一个 Webhook 测试请求",
      sample: {
        table: "manual_test",
        operation: "TEST",
      },
    };

    const headers: Record<string, string> = {
      "Content-Type": "application/json",
      "X-Love-Source": "love-app",
    };

    if (body.webhookSecret) {
      headers["X-Love-Webhook-Secret"] = body.webhookSecret;
    }

    const response = await fetch(body.webhookUrl, {
      method: "POST",
      headers,
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const detail = await response.text();
      return NextResponse.json({ error: "Webhook request failed", detail }, { status: 502 });
    }

    return NextResponse.json({ ok: true });
  } catch (error) {
    console.error("notification test failed:", error);
    return NextResponse.json({ error: "Unexpected error" }, { status: 500 });
  }
}
