#!/usr/bin/env python3
"""Web upload server for SamplePi media files.

Serves a browser-based UI on port 8080 so WAV files can be uploaded
to /home/pi/media over the local network without SSH.
"""

import os
import sys
from flask import Flask, request, jsonify, render_template_string

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 500 * 1024 * 1024  # 500 MB max upload

if os.environ.get('MEDIA_PATH_TYPE') == 'production':
    MEDIA_ROOT = '/home/pi/media'
else:
    # Dev: use test_media relative to project root
    MEDIA_ROOT = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        'test_media'
    )

CATEGORIES = {
    'test_wavs': os.path.join(MEDIA_ROOT, 'test_wavs'),
    'samples':   os.path.join(MEDIA_ROOT, 'samples'),
}

HTML = '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>SamplePi — File Manager</title>
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    background: #14141e; color: #fff;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    min-height: 100vh; padding: 24px 16px;
  }
  h1 { font-size: 1.4rem; margin-bottom: 24px; color: #6496ff; letter-spacing: .05em; }
  .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
  .card {
    background: #1e1e2e; border-radius: 10px; padding: 20px;
    border: 1px solid #2e2e4e;
  }
  .card h2 { font-size: 1rem; margin-bottom: 16px; color: #a0b4ff; }
  .drop-zone {
    border: 2px dashed #3c3c5c; border-radius: 8px; padding: 24px;
    text-align: center; cursor: pointer; transition: border-color .2s, background .2s;
    margin-bottom: 14px; font-size: .875rem; color: #888;
  }
  .drop-zone.dragover { border-color: #6496ff; background: #1a1a2e; color: #aac; }
  .drop-zone input[type=file] { display: none; }
  .btn {
    display: inline-block; padding: 8px 18px; border-radius: 6px; border: none;
    cursor: pointer; font-size: .875rem; font-weight: 600; transition: opacity .15s;
  }
  .btn:hover { opacity: .85; }
  .btn-primary { background: #4060a0; color: #fff; }
  .btn-danger  { background: #602020; color: #fff; padding: 4px 10px; font-size: .75rem; }
  .file-list { list-style: none; margin-top: 14px; }
  .file-list li {
    display: flex; justify-content: space-between; align-items: center;
    padding: 7px 0; border-bottom: 1px solid #2a2a3a; font-size: .85rem;
  }
  .file-list li:last-child { border-bottom: none; }
  .file-name { color: #ccc; word-break: break-all; flex: 1; margin-right: 8px; }
  .file-size { color: #666; font-size: .75rem; white-space: nowrap; margin-right: 10px; }
  .toast {
    position: fixed; bottom: 20px; right: 20px;
    background: #2a3a5a; color: #9ab; padding: 10px 18px;
    border-radius: 8px; font-size: .875rem; opacity: 0;
    transition: opacity .3s; pointer-events: none; z-index: 999;
  }
  .toast.show { opacity: 1; }
  .progress-bar-wrap {
    height: 4px; background: #2e2e4e; border-radius: 2px;
    margin-bottom: 10px; overflow: hidden; display: none;
  }
  .progress-bar { height: 100%; background: #6496ff; width: 0; transition: width .1s; }
  .empty { color: #555; font-size: .8rem; padding: 8px 0; }
</style>
</head>
<body>
<h1>SamplePi — File Manager</h1>
<div class="grid" id="grid"></div>
<div class="toast" id="toast"></div>

<script>
const CATS = ['test_wavs', 'samples'];
const LABELS = { test_wavs: 'Test WAVs', samples: 'Samples' };

function fmtSize(bytes) {
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
  return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
}

function toast(msg, isErr) {
  const el = document.getElementById('toast');
  el.textContent = msg;
  el.style.background = isErr ? '#3a2020' : '#2a3a5a';
  el.classList.add('show');
  setTimeout(() => el.classList.remove('show'), 3000);
}

async function loadFiles(cat) {
  const res = await fetch('/api/files/' + cat);
  const files = await res.json();
  const ul = document.getElementById('list-' + cat);
  ul.innerHTML = '';
  if (!files.length) {
    ul.innerHTML = '<li><span class="empty">No files yet</span></li>';
    return;
  }
  files.forEach(f => {
    const li = document.createElement('li');
    li.innerHTML = `
      <span class="file-name">${f.name}</span>
      <span class="file-size">${fmtSize(f.size)}</span>
      <button class="btn btn-danger" onclick="deleteFile('${cat}','${f.name}')">Delete</button>
    `;
    ul.appendChild(li);
  });
}

async function deleteFile(cat, name) {
  if (!confirm('Delete ' + name + '?')) return;
  const res = await fetch('/api/files/' + cat + '/' + encodeURIComponent(name), { method: 'DELETE' });
  const data = await res.json();
  if (res.ok) { toast('Deleted ' + name); loadFiles(cat); }
  else toast(data.error || 'Delete failed', true);
}

async function uploadFiles(cat, files) {
  const bar = document.getElementById('bar-' + cat);
  const wrap = document.getElementById('bar-wrap-' + cat);
  wrap.style.display = 'block';
  bar.style.width = '0';
  let done = 0;
  for (const file of files) {
    if (!file.name.toLowerCase().endsWith('.wav')) {
      toast(file.name + ' skipped (not a .wav)', true);
      done++;
      bar.style.width = (done / files.length * 100) + '%';
      continue;
    }
    const fd = new FormData();
    fd.append('file', file);
    const res = await fetch('/api/upload/' + cat, { method: 'POST', body: fd });
    const data = await res.json();
    if (!res.ok) toast(data.error || 'Upload failed: ' + file.name, true);
    done++;
    bar.style.width = (done / files.length * 100) + '%';
  }
  toast('Upload complete');
  wrap.style.display = 'none';
  loadFiles(cat);
}

function buildCard(cat) {
  const div = document.createElement('div');
  div.className = 'card';
  div.innerHTML = `
    <h2>${LABELS[cat]}</h2>
    <div class="progress-bar-wrap" id="bar-wrap-${cat}">
      <div class="progress-bar" id="bar-${cat}"></div>
    </div>
    <div class="drop-zone" id="drop-${cat}">
      <input type="file" id="input-${cat}" accept=".wav" multiple>
      Drop .wav files here or <strong>click to browse</strong>
    </div>
    <ul class="file-list" id="list-${cat}"></ul>
  `;
  const zone = div.querySelector('.drop-zone');
  const input = div.querySelector('input[type=file]');
  zone.addEventListener('click', () => input.click());
  zone.addEventListener('dragover', e => { e.preventDefault(); zone.classList.add('dragover'); });
  zone.addEventListener('dragleave', () => zone.classList.remove('dragover'));
  zone.addEventListener('drop', e => {
    e.preventDefault(); zone.classList.remove('dragover');
    uploadFiles(cat, [...e.dataTransfer.files]);
  });
  input.addEventListener('change', () => { uploadFiles(cat, [...input.files]); input.value = ''; });
  return div;
}

const grid = document.getElementById('grid');
CATS.forEach(cat => { grid.appendChild(buildCard(cat)); loadFiles(cat); });
</script>
</body>
</html>'''


@app.route('/')
def index():
    return render_template_string(HTML)


@app.route('/api/files/<category>')
def list_files(category):
    if category not in CATEGORIES:
        return jsonify({'error': 'Unknown category'}), 400
    d = CATEGORIES[category]
    os.makedirs(d, exist_ok=True)
    files = []
    for name in sorted(os.listdir(d)):
        if name.lower().endswith('.wav'):
            path = os.path.join(d, name)
            files.append({'name': name, 'size': os.path.getsize(path)})
    return jsonify(files)


@app.route('/api/upload/<category>', methods=['POST'])
def upload_file(category):
    if category not in CATEGORIES:
        return jsonify({'error': 'Unknown category'}), 400
    f = request.files.get('file')
    if not f or not f.filename:
        return jsonify({'error': 'No file provided'}), 400
    name = os.path.basename(f.filename)
    if not name.lower().endswith('.wav'):
        return jsonify({'error': 'Only .wav files are accepted'}), 400

    d = CATEGORIES[category]
    os.makedirs(d, exist_ok=True)
    f.save(os.path.join(d, name))
    return jsonify({'saved': name}), 201


@app.route('/api/files/<category>/<filename>', methods=['DELETE'])
def delete_file(category, filename):
    if category not in CATEGORIES:
        return jsonify({'error': 'Unknown category'}), 400
    name = os.path.basename(filename)
    path = os.path.join(CATEGORIES[category], name)
    if not os.path.exists(path):
        return jsonify({'error': 'File not found'}), 404
    os.remove(path)
    return jsonify({'deleted': name})


if __name__ == '__main__':
    port = int(os.environ.get('UPLOAD_PORT', 8080))
    print(f"SamplePi upload server on http://0.0.0.0:{port}")
    app.run(host='0.0.0.0', port=port, threaded=True)
