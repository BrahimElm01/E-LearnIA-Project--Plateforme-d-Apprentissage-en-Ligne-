import { User } from './user.model';

export interface Course {
  id: number;
  title: string;
  description: string;
  teacher: User;
  imageUrl?: string;
  published: boolean;
  progress?: number;
  completed?: boolean;
}

export interface StudentCourse {
  id: number;
  title: string;
  description: string;
  teacherName: string;
  imageUrl?: string;
  progress: number; // 0..100
  completed: boolean;
}

export interface TeacherCourse {
  id: number;
  title: string;
  description: string;
  published: boolean;
  imageUrl?: string;
}

export interface CourseAnalytics {
  totalStudents: number;
  activeCourses: number;
  averageRating: number;
}

export interface StudentProgress {
  studentId: number;
  fullName: string;
  email: string;
  progress: number; // 0..100
  completed: boolean;
  rating?: number; // 1..5
}


