import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { prisma } from '../../config/prisma';
import { env } from '../../config/env';
import { AppError } from '../../middleware/error.middleware';
import { RegisterBusinessInput, LoginInput } from './auth.schema';
import { AuthUser } from '../../middleware/auth.middleware';

export class AuthService {
  async registerBusiness(data: RegisterBusinessInput) {
    // Check if username is taken in any business or globally if desired
    const existingUser = await prisma.users.findFirst({
      where: { username: data.username },
    });
    if (existingUser) {
      throw new AppError(409, 'Username is already registered.');
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(data.password, salt);

    return await prisma.$transaction(async (tx) => {
      // 1. Create Business
      const business = await tx.businesses.create({
        data: {
          name: data.businessName,
          tagline: data.tagline,
          phone: data.phone,
          address: data.address,
          gstin: data.gstin,
        },
      });

      // 2. Ensure cursor entry exists
      await tx.business_sync_cursors.create({
        data: {
          business_id: business.id,
          last_cursor: 0,
        },
      });

      // 3. Create Admin User
      const user = await tx.users.create({
        data: {
          business_id: business.id,
          username: data.username,
          full_name: data.fullName,
          role_id: 'admin',
          password_hash: passwordHash,
          salt: salt,
          is_active: true,
        },
      });

      // 4. Default Business Settings
      const defaultSettings = [
        { setting_key: 'tax_rate', setting_value: '5.0' },
        { setting_key: 'tax_inclusive', setting_value: 'true' },
        { setting_key: 'printer_paper_width', setting_value: '80mm' },
        { setting_key: 'invoice_prefix', setting_value: 'INV-' },
      ];

      for (const s of defaultSettings) {
        await tx.business_settings.create({
          data: {
            business_id: business.id,
            setting_key: s.setting_key,
            setting_value: s.setting_value,
          },
        });
      }

      const token = this.generateToken({
        userId: user.id,
        businessId: business.id,
        role: 'admin',
        username: user.username,
      });

      return {
        business: {
          id: business.id,
          name: business.name,
          phone: business.phone,
        },
        user: {
          id: user.id,
          username: user.username,
          fullName: user.full_name,
          role: user.role_id,
        },
        token,
      };
    });
  }

  async login(data: LoginInput) {
    // Find user by username
    const user = await prisma.users.findFirst({
      where: {
        username: data.username,
        ...(data.businessId ? { business_id: data.businessId } : {}),
      },
      include: {
        businesses: true,
      },
    });

    if (!user || !user.is_active) {
      throw new AppError(401, 'Invalid username or password.');
    }

    const isValid = await bcrypt.compare(data.password, user.password_hash);
    if (!isValid) {
      throw new AppError(401, 'Invalid username or password.');
    }

    let deviceId: string | undefined;

    // Authorize or register device if provided
    if (data.deviceUid) {
      const device = await prisma.devices.upsert({
        where: {
          business_id_device_uid: {
            business_id: user.business_id,
            device_uid: data.deviceUid,
          },
        },
        update: {
          device_name: data.deviceName || 'Android Terminal',
          last_seen_at: new Date(),
        },
        create: {
          business_id: user.business_id,
          device_uid: data.deviceUid,
          device_name: data.deviceName || 'Android Terminal',
          is_authorized: true, // Default to authorized in trusted private network
          authorized_at: new Date(),
          last_seen_at: new Date(),
        },
      });
      deviceId = device.id;
    }

    const token = this.generateToken({
      userId: user.id,
      businessId: user.business_id,
      role: user.role_id as 'admin' | 'cashier',
      username: user.username,
      deviceId,
    });

    return {
      user: {
        id: user.id,
        username: user.username,
        fullName: user.full_name,
        role: user.role_id,
      },
      business: {
        id: user.businesses.id,
        name: user.businesses.name,
        invoicePrefix: user.businesses.invoice_prefix,
        printerWidth: user.businesses.printer_width,
      },
      deviceId,
      token,
    };
  }

  async getMe(userId: string) {
    const user = await prisma.users.findUnique({
      where: { id: userId },
      include: { businesses: true },
    });
    if (!user) {
      throw new AppError(404, 'User not found.');
    }
    return {
      id: user.id,
      username: user.username,
      fullName: user.full_name,
      role: user.role_id,
      business: {
        id: user.businesses.id,
        name: user.businesses.name,
        tagline: user.businesses.tagline,
        address: user.businesses.address,
        phone: user.businesses.phone,
        gstin: user.businesses.gstin,
      },
    };
  }

  private generateToken(payload: AuthUser): string {
    return jwt.sign(payload, env.JWT_SECRET, {
      expiresIn: env.JWT_EXPIRES_IN as any,
    });
  }
}

export const authService = new AuthService();
