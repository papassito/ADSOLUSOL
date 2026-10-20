import fs from 'fs';
import path from 'path';
import { initialData } from './initialData';

const DB_PATH = path.join(process.cwd(), 'adsolusol_enterprise_db.json');
export { DB_PATH };

export function readDb() {
  try {
    if (!fs.existsSync(DB_PATH)) {
      fs.writeFileSync(DB_PATH, JSON.stringify(initialData, null, 2), 'utf-8');
      return initialData;
    }
    return JSON.parse(fs.readFileSync(DB_PATH, 'utf-8'));
  } catch (e) {
    return initialData;
  }
}

export function writeDb(data: any) {
  try {
    fs.writeFileSync(DB_PATH, JSON.stringify(data, null, 2), 'utf-8');
  } catch (e) {
    console.error('Error escribiendo DB:', e);
  }
}

