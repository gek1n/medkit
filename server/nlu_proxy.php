<?php
/**
 * MedKit NLU Proxy
 * Deploy to: https://YOUR_DOMAIN/medkit/nlu.php
 * Set ANTHROPIC_KEY below (never expose in mobile app).
 */

define('ANTHROPIC_KEY', 'sk-ant-REPLACE_ME');
define('ANTHROPIC_MODEL', 'claude-haiku-4-5-20251001');
define('ALLOWED_ORIGIN', '*'); // restrict to your domain in prod, e.g. 'capacitor://localhost'

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: ' . ALLOWED_ORIGIN);
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

$body = json_decode(file_get_contents('php://input'), true);
$transcript = trim($body['transcript'] ?? '');

if ($transcript === '') {
    http_response_code(400);
    echo json_encode(['error' => 'transcript is required']);
    exit;
}

$system = <<<'PROMPT'
You are a parser for a Ukrainian family medication manager app's voice
ADD feature. This feature supports exactly THREE intents — do not infer
any other action type, even if the phrase resembles one.
Parse the user's voice command and return ONLY a valid JSON object — no explanations, no markdown.

JSON schema:
{
  "action": "add_med" | "add_activity" | "add_appointment" | "unknown",
  "drugName": string | null,
  "doseAmount": number | null,
  "doseUnit": string | null,
  "scheduleTimes": ["morning","evening","afternoon","night"] | null,
  "foodRelation": "before" | "after" | "any" | null,
  "activityName": string | null,
  "appointmentType": string | null
}

Rules:
- "додай/додати/запиши ліки/препарат [name]" → add_med
- "додай/додати зарядку/тренування/прогулянку/вправу/йогу/активність [name]" → add_activity, activityName = normalized activity name (e.g. "зарядка", "прогулянка")
- "запис/нагадування до лікаря/кардіолога/терапевта" → add_appointment
- Anything that isn't clearly one of these three (e.g. "прийняв таблетку", a symptom/mood description, small talk) → unknown. Never guess add_med just because the phrase contains "додай".
- вранці/ранком → morning, ввечері/вечором → evening, вдень → afternoon, вночі → night
- до їжі → before, після їжі → after
- Fill in only what you can confidently infer. Leave unknown fields as null.
PROMPT;

$payload = json_encode([
    'model'      => ANTHROPIC_MODEL,
    'max_tokens' => 512,
    'system'     => $system,
    'messages'   => [['role' => 'user', 'content' => $transcript]],
]);

$ch = curl_init('https://api.anthropic.com/v1/messages');
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST           => true,
    CURLOPT_POSTFIELDS     => $payload,
    CURLOPT_TIMEOUT        => 20,
    CURLOPT_HTTPHEADER     => [
        'x-api-key: '          . ANTHROPIC_KEY,
        'anthropic-version: 2023-06-01',
        'content-type: application/json',
    ],
]);

$raw  = curl_exec($ch);
$code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$err  = curl_error($ch);
curl_close($ch);

if ($err !== '') {
    http_response_code(502);
    echo json_encode(['error' => 'curl: ' . $err]);
    exit;
}

if ($code !== 200) {
    http_response_code(502);
    echo json_encode(['error' => 'upstream ' . $code, 'detail' => $raw]);
    exit;
}

$resp = json_decode($raw, true);
$text = $resp['content'][0]['text'] ?? '';

// Strip markdown fences if model adds them
$clean = preg_replace('/^```json\s*/m', '', $text);
$clean = preg_replace('/^```\s*/m', '', $clean);
$clean = trim($clean);

$nlu = json_decode($clean, true);
if ($nlu === null) {
    http_response_code(502);
    echo json_encode(['error' => 'invalid JSON from model', 'raw' => $text]);
    exit;
}

echo json_encode($nlu);
