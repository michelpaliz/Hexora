class HexoraEmailTemplatePreset {
  static const String defaultName = 'Hexora App Template';
  static const String defaultSubject =
      'Hexora | Important update for {{user_name}}';

  static String textBody() {
    return '''
Hi {{user_name}},

We have a new update for your Hexora account.

{{message}}

Open Hexora:
{{action_url}}

If you did not request this email, you can ignore it.

— Hexora Team
''';
  }

  static String htmlBody() {
    return '''
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Hexora</title>
    <style>
      body {
        margin: 0;
        padding: 0;
        background: #f3f7fb;
        font-family: "Segoe UI", Arial, sans-serif;
        color: #1b2a40;
      }
      .shell {
        width: 100%;
        padding: 24px 12px;
      }
      .card {
        max-width: 640px;
        margin: 0 auto;
        border-radius: 16px;
        overflow: hidden;
        background: #ffffff;
        border: 1px solid #d8e3f1;
        box-shadow: 0 10px 28px rgba(21, 52, 98, 0.08);
      }
      .hero {
        padding: 22px 24px;
        background: linear-gradient(135deg, #0f4fa8 0%, #2b77d2 55%, #5fa8ff 100%);
        color: #ffffff;
      }
      .brand {
        margin: 0;
        font-size: 20px;
        line-height: 1.2;
        font-weight: 700;
        letter-spacing: 0.2px;
      }
      .subtitle {
        margin-top: 8px;
        font-size: 13px;
        opacity: 0.92;
      }
      .content {
        padding: 24px;
        font-size: 15px;
        line-height: 1.6;
      }
      .title {
        margin: 0 0 14px 0;
        color: #123c72;
        font-size: 22px;
        line-height: 1.25;
      }
      .copy {
        margin: 0 0 16px 0;
      }
      .message-box {
        margin: 16px 0 22px 0;
        padding: 14px 16px;
        border-left: 4px solid #2b77d2;
        border-radius: 10px;
        background: #f4f8ff;
        color: #233e60;
        font-size: 14px;
      }
      .cta {
        display: inline-block;
        text-decoration: none;
        padding: 12px 18px;
        border-radius: 10px;
        background: #1f63b9;
        color: #ffffff !important;
        font-weight: 600;
      }
      .footer {
        margin-top: 22px;
        font-size: 12px;
        color: #647891;
      }
      @media (max-width: 480px) {
        .hero, .content {
          padding: 18px;
        }
        .title {
          font-size: 20px;
        }
      }
    </style>
  </head>
  <body>
    <div class="shell">
      <div class="card">
        <div class="hero">
          <p class="brand">Hexora</p>
          <p class="subtitle">Smart operations for modern teams</p>
        </div>
        <div class="content">
          <h1 class="title">Hello {{user_name}}</h1>
          <p class="copy">
            We have a new update for your Hexora account.
          </p>
          <div class="message-box">
            {{message}}
          </div>
          <a class="cta" href="{{action_url}}" target="_blank" rel="noopener noreferrer">
            Open Hexora
          </a>
          <p class="footer">
            If you did not request this email, you can safely ignore it.
            <br />
            — Hexora Team
          </p>
        </div>
      </div>
    </div>
  </body>
</html>
''';
  }
}
