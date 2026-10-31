import bcrypt from 'bcryptjs';
import { prisma } from '../../config/prisma';
import { AppError } from '../../middleware/error.middleware';
import { CreateStaffUserInput, UpdateUserStatusInput } from './users.schema';

export class UsersService {
  async listUsers(businessId: string) {
    return prisma.users.findMany({
      where: { business_id: businessId },
      select: {
        id: true,
        business_id: true,
        username: true,
        full_name: true,
        role_id: true,
        is_active: true,
        created_at: true,
      },
      orderBy: { created_at: 'asc' },
    });
  }

  async createStaffUser(businessId: string, data: CreateStaffUserInput) {
    const existing = await prisma.users.findFirst({
      where: { business_id: businessId, username: data.username },
    });
    if (existing) {
      throw new AppError(409, 'Username already exists in this business');
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(data.password, salt);

    const user = await prisma.users.create({
      data: {
        business_id: businessId,
        username: data.username,
        full_name: data.fullName,
        role_id: data.role,
        password_hash: passwordHash,
        salt,
        is_active: true,
      },
    });

    return {
      id: user.id,
      username: user.username,
      fullName: user.full_name,
      role: user.role_id,
      isActive: user.is_active,
    };
  }

  async setUserStatus(businessId: string, id: string, data: UpdateUserStatusInput) {
    const user = await prisma.users.findFirst({
      where: { id, business_id: businessId },
    });
    if (!user) {
      throw new AppError(404, 'User not found');
    }

    return prisma.users.update({
      where: { id },
      data: { is_active: data.isActive },
      select: {
        id: true,
        username: true,
        is_active: true,
      },
    });
  }
}

export const usersService = new UsersService();
