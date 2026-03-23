_embedded_ui() {
  cat <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>OctClaw Mini</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;background:#f5f5f5;color:#333;height:100vh;display:flex;flex-direction:column}
header{padding:12px 20px;background:#fff;border-bottom:1px solid #ddd;display:flex;align-items:center;gap:12px;box-shadow:0 2px 4px rgba(0,0,0,0.1)}
header h1{font-size:16px;color:#1976d2}
header select,header button{background:#f0f0f0;color:#333;border:1px solid #ccc;border-radius:6px;padding:4px 10px;font-size:13px;cursor:pointer}
header button:hover{background:#e0e0e0}
#chat{flex:1;overflow-y:auto;padding:20px;display:flex;flex-direction:column;gap:12px}
.msg{max-width:80%;padding:10px 14px;border-radius:12px;line-height:1.5;font-size:14px;white-space:pre-wrap;word-wrap:break-word}
.msg.user{align-self:flex-end;background:#cce5ff;border:1px solid #99ccff;color:#003d99}
.msg.assistant{align-self:flex-start;background:#f0f0f0;border:1px solid #ddd;color:#333}
.msg.tool{align-self:flex-start;background:#e8f5e9;border:1px solid #c8e6c9;font-size:12px;font-family:monospace;max-height:200px;overflow-y:auto;color:#1b5e20}
.msg.error{background:#ffebee;border:1px solid #ffcccc;color:#d32f2f}
#input-bar{padding:12px 20px;background:#fff;border-top:1px solid #ddd;display:flex;gap:8px}
#input-bar textarea{flex:1;background:#f9f9f9;color:#333;border:1px solid #ccc;border-radius:8px;padding:10px;font-size:14px;resize:none;min-height:44px;max-height:120px;font-family:inherit}
#input-bar button{background:#1976d2;color:#fff;border:none;border-radius:8px;padding:10px 20px;font-size:14px;cursor:pointer}
#input-bar button:hover{background:#1565c0}
#input-bar button:disabled{background:#bbb;cursor:not-allowed}
.typing{color:#666;font-style:italic;font-size:13px}
</style>
</head>
<body>
<header>
  <h1>🐙 OctClaw Mini</h1>
  <select id="session"></select>
  <button onclick="newSession()">+ New</button>
  <button onclick="deleteSession()">🗑 Delete</button>
</header>
<div id="chat"></div>
<div id="input-bar">
  <textarea id="msg" placeholder="Type a message... (Shift+Enter for newline)" rows="1"></textarea>
  <button id="send-btn" onclick="send()">Send</button>
</div>
<script>
const API = window.location.origin;
let currentSession = 'default';

const $chat = document.getElementById('chat');
const $msg = document.getElementById('msg');
const $session = document.getElementById('session');
const $btn = document.getElementById('send-btn');

$msg.addEventListener('keydown', e => {
  if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send(); }
});

function addMsg(role, text) {
  const d = document.createElement('div');
  d.className = 'msg ' + role;
  d.textContent = text;
  $chat.appendChild(d);
  $chat.scrollTop = $chat.scrollHeight;
  return d;
}

async function send() {
  const msg = $msg.value.trim();
  if (!msg) return;
  $msg.value = '';
  $btn.disabled = true;
  addMsg('user', msg);
  const typing = addMsg('assistant', '⏳ Thinking...');
  typing.classList.add('typing');
  try {
    const res = await fetch(API + '/api/chat', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({session: currentSession, message: msg})
    });
    const data = await res.json();
    typing.remove();
    if (data.error) addMsg('error', data.error);
    else addMsg('assistant', data.reply || '(empty response)');
  } catch(e) {
    typing.remove();
    addMsg('error', 'Request failed: ' + e.message);
  }
  $btn.disabled = false;
  $msg.focus();
}

async function loadSessions() {
  try {
    const res = await fetch(API + '/api/sessions');
    const data = await res.json();
    $session.innerHTML = '';
    const sessions = data.sessions || [];
    if (!sessions.includes('default')) sessions.unshift('default');
    sessions.forEach(s => {
      const opt = document.createElement('option');
      opt.value = s; opt.textContent = s;
      if (s === currentSession) opt.selected = true;
      $session.appendChild(opt);
    });
  } catch(e) { console.error(e); }
}

$session.addEventListener('change', () => {
  currentSession = $session.value;
  $chat.innerHTML = '';
});

function newSession() {
  const name = prompt('Session name:');
  if (!name) return;
  currentSession = name.replace(/[^a-zA-Z0-9_-]/g, '');
  loadSessions();
  $chat.innerHTML = '';
}

async function deleteSession() {
  if (!confirm('Delete session "' + currentSession + '"?')) return;
  await fetch(API + '/api/session/' + currentSession, {method:'DELETE'});
  currentSession = 'default';
  $chat.innerHTML = '';
  loadSessions();
}

loadSessions();
$msg.focus();
</script>
</body>
</html>
HTMLEOF
}

