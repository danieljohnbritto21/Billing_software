import { z } from 'zod';

export const registerDeviceSchema = z.object({
  deviceUid: z.string().min(1).max(128),
  deviceName: z.string().min(1).max(100),
  tailscaleIp: z.string().max(45).optional(),
});

export const updateDeviceAuthSchema = z.object({
  isAuthorized: z.boolean(),
});

export type RegisterDeviceInput = z.infer<typeof registerDeviceSchema>;
export type UpdateDeviceAuthInput = z.infer<typeof updateDeviceAuthSchema>;
