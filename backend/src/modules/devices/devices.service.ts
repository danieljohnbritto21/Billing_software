import { prisma } from '../../config/prisma';
import { AppError } from '../../middleware/error.middleware';
import { RegisterDeviceInput, UpdateDeviceAuthInput } from './devices.schema';

export class DevicesService {
  async listDevices(businessId: string) {
    return prisma.devices.findMany({
      where: { business_id: businessId },
      orderBy: { created_at: 'desc' },
    });
  }

  async registerDevice(businessId: string, data: RegisterDeviceInput) {
    const clientIp = data.ipAddress || data.tailscaleIp;
    return prisma.devices.upsert({
      where: {
        business_id_device_uid: {
          business_id: businessId,
          device_uid: data.deviceUid,
        },
      },
      update: {
        device_name: data.deviceName,
        tailscale_ip: clientIp,
        last_seen_at: new Date(),
      },
      create: {
        business_id: businessId,
        device_uid: data.deviceUid,
        device_name: data.deviceName,
        tailscale_ip: clientIp,
        is_authorized: false, // Requires Admin authorization
        last_seen_at: new Date(),
      },
    });
  }

  async setDeviceAuthorization(businessId: string, id: string, data: UpdateDeviceAuthInput) {
    const device = await prisma.devices.findFirst({
      where: { id, business_id: businessId },
    });
    if (!device) {
      throw new AppError(404, 'Device not found');
    }

    const updated = await prisma.devices.update({
      where: { id },
      data: {
        is_authorized: data.isAuthorized,
        authorized_at: data.isAuthorized ? new Date() : null,
      },
    });

    await prisma.user_sessions.updateMany({
      where: { device_id: id, business_id: businessId },
      data: { is_revoked: !data.isAuthorized },
    }).catch(() => {});

    return updated;
  }

  async heartbeat(businessId: string, deviceUid: string) {
    return prisma.devices.updateMany({
      where: { business_id: businessId, device_uid: deviceUid },
      data: { last_seen_at: new Date() },
    });
  }
}

export const devicesService = new DevicesService();
