import { Response } from 'express';

export function apiSuccess<T>(
  res: Response,
  data: T,
  message?: string,
  statusCode = 200
) {
  return res.status(statusCode).json({
    success: true,
    message,
    data,
  });
}

export function apiPaginated<T>(
  res: Response,
  items: T[],
  total: number,
  page: number,
  limit: number,
  extra?: Record<string, any>
) {
  return res.status(200).json({
    success: true,
    data: items,
    pagination: {
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      ...extra,
    },
  });
}
