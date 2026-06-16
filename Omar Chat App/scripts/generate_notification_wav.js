const fs = require('fs');
const path = require('path');

const sampleRate = 44100;
const duration = 0.35;
const frequency = 880;
const samples = Math.floor(sampleRate * duration);
const dataSize = samples * 2;
const buffer = Buffer.alloc(44 + dataSize);

buffer.write('RIFF', 0);
buffer.writeUInt32LE(36 + dataSize, 4);
buffer.write('WAVE', 8);
buffer.write('fmt ', 12);
buffer.writeUInt32LE(16, 16);
buffer.writeUInt16LE(1, 20);
buffer.writeUInt16LE(1, 22);
buffer.writeUInt32LE(sampleRate, 24);
buffer.writeUInt32LE(sampleRate * 2, 28);
buffer.writeUInt16LE(2, 32);
buffer.writeUInt16LE(16, 34);
buffer.write('data', 36);
buffer.writeUInt32LE(dataSize, 40);

for (let i = 0; i < samples; i++) {
  const t = i / sampleRate;
  const envelope = Math.min(1, (samples - i) / (sampleRate * 0.08));
  const sample = Math.sin(2 * Math.PI * frequency * t) * 0.35 * envelope;
  const intSample = Math.max(-32768, Math.min(32767, Math.floor(sample * 32767)));
  buffer.writeInt16LE(intSample, 44 + i * 2);
}

const out = path.join(__dirname, '..', 'assets', 'sounds', 'message_notification.wav');
fs.writeFileSync(out, buffer);
console.log('Wrote', out);
