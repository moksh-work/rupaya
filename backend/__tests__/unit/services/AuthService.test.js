/**
 * Unit Tests for AuthService
 * Tests authentication logic, JWT generation, password hashing
 */

const AuthService = require('../../../src/services/AuthService');
const jwt = require('jsonwebtoken');
const bcryptjs = require('bcryptjs');

// Mock dependencies
jest.mock('jsonwebtoken');
jest.mock('bcryptjs');

describe('AuthService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('generateJWT', () => {
    it('should generate valid JWT token', () => {
      const payload = { userId: '123', email: 'test@example.com' };
      const expectedToken = 'mock-jwt-token';
      
      jwt.sign.mockReturnValue(expectedToken);
      
      const token = AuthService.generateJWT(payload);
      
      expect(token).toBe(expectedToken);
      expect(jwt.sign).toHaveBeenCalledWith(
        payload,
        process.env.JWT_SECRET,
        { expiresIn: '24h' }
      );
    });

    it('should throw error if JWT generation fails', () => {
      jwt.sign.mockImplementation(() => {
        throw new Error('JWT generation failed');
      });
      
      expect(() => {
        AuthService.generateJWT({ userId: '123' });
      }).toThrow('JWT generation failed');
    });
  });

  describe('verifyJWT', () => {
    it('should verify valid JWT token', () => {
      const token = 'valid-token';
      const payload = { userId: '123', email: 'test@example.com' };
      
      jwt.verify.mockReturnValue(payload);
      
      const verified = AuthService.verifyJWT(token);
      
      expect(verified).toEqual(payload);
      expect(jwt.verify).toHaveBeenCalledWith(token, process.env.JWT_SECRET);
    });

    it('should throw error for invalid token', () => {
      jwt.verify.mockImplementation(() => {
        throw new Error('Invalid token');
      });
      
      expect(() => {
        AuthService.verifyJWT('invalid-token');
      }).toThrow('Invalid token');
    });
  });

  describe('hashPassword', () => {
    it('should hash password successfully', async () => {
      const password = 'SecurePass123!';
      const hashedPassword = 'hashed-password-hash';
      
      bcryptjs.hash.mockResolvedValue(hashedPassword);
      
      const result = await AuthService.hashPassword(password);
      
      expect(result).toBe(hashedPassword);
      expect(bcryptjs.hash).toHaveBeenCalledWith(password, 10);
    });

    it('should throw error if hashing fails', async () => {
      bcryptjs.hash.mockRejectedValue(new Error('Hashing failed'));
      
      await expect(
        AuthService.hashPassword('password')
      ).rejects.toThrow('Hashing failed');
    });
  });

  describe('comparePasswords', () => {
    it('should return true for matching passwords', async () => {
      const password = 'SecurePass123!';
      const hashedPassword = 'hashed-password-hash';
      
      bcryptjs.compare.mockResolvedValue(true);
      
      const result = await AuthService.comparePasswords(password, hashedPassword);
      
      expect(result).toBe(true);
      expect(bcryptjs.compare).toHaveBeenCalledWith(password, hashedPassword);
    });

    it('should return false for non-matching passwords', async () => {
      bcryptjs.compare.mockResolvedValue(false);
      
      const result = await AuthService.comparePasswords(
        'wrongPassword',
        'hashed-password'
      );
      
      expect(result).toBe(false);
    });
  });

  describe('validatePasswordStrength', () => {
    it('should pass strong password', () => {
      const strongPassword = 'SecurePass123!@#';
      
      expect(
        AuthService.validatePasswordStrength(strongPassword)
      ).toBe(true);
    });

    it('should fail weak password (too short)', () => {
      const weakPassword = 'Short1!';
      
      expect(
        AuthService.validatePasswordStrength(weakPassword)
      ).toBe(false);
    });

    it('should fail password without uppercase', () => {
      const noUppercase = 'secureppass123!@#';
      
      expect(
        AuthService.validatePasswordStrength(noUppercase)
      ).toBe(false);
    });

    it('should fail password without numbers', () => {
      const noNumbers = 'SecurePassword!@#';
      
      expect(
        AuthService.validatePasswordStrength(noNumbers)
      ).toBe(false);
    });

    it('should fail password without special characters', () => {
      const noSpecial = 'SecurePassword123';
      
      expect(
        AuthService.validatePasswordStrength(noSpecial)
      ).toBe(false);
    });
  });
});
