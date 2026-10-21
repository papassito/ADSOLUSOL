import fs from 'fs';
import path from 'path';
import { initialData } from './initialData';

const DB_PATH = path.join(process.cwd(), 'adsolusol_enterprise_db.json');
export { DB_PATH };

export function readDb() {
  if (!fs.existsSync(DB_PATH)) {
    fs.writeFileSync(DB_PATH, JSON.stringify(initialData, null, 2), { encoding: 'utf-8', flag: 'wx' });
  }
  return JSON.parse(fs.readFileSync(DB_PATH, 'utf-8'));
}

export function writeDb(data: any) {
  const temporary = `${DB_PATH}.${process.pid}.${Date.now()}.tmp`;
  try {
    fs.writeFileSync(temporary, JSON.stringify(data, null, 2), { encoding: 'utf-8', flag: 'wx' });
    fs.renameSync(temporary, DB_PATH);
  } finally {
    if (fs.existsSync(temporary)) fs.unlinkSync(temporary);
  }
}

