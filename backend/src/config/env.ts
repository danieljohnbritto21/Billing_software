import dotenv from 'dotenv';
import path from 'path';
import { z } from 'zod';

dotenv.config();

const defaultStorage = process.env.IMAGE_STORAGE_PATH || path.resolve(process.cwd(), 'storage/images');

const envSchema = z.object({
  PORT: z.coerce.number().default(3000),
  HOST: z.string().default('0.0.0.0'),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),
  JWT_SECRET: z.string().min(16, 'JWT_SECRET must be at least 16 characters'),
  JWT_EXPIRES_IN: z.string().default('7d'),
  IMAGE_STORAGE_PATH: z.string().default(defaultStorage),
});

let parsedEnv: z.infer<typeof envSchema>;

try {
  parsedEnv = envSchema.parse(process.env);
} catch (err: unknown) {
  if (err instanceof z.ZodError) {
    console.error('❌ Invalid environment configuration:', JSON.stringify(err.format(), null, 2));
  } else {
    console.error('❌ Invalid environment configuration:', err);
  }
  process.exit(1);
}

export const env: z.infer<typeof envSchema> = parsedEnv;
