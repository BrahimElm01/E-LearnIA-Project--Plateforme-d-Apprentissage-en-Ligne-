export interface GeneratedLesson {
  title: string;
  description: string;
  orderIndex: number;
  estimatedDuration: number;
  videoUrl?: string;
}

export interface GeneratedQuestion {
  text: string;
  options: string[];
  correctAnswer: string;
  points?: number;
}

export interface GeneratedQuiz {
  title: string;
  description: string;
  questions: GeneratedQuestion[];
}

export interface GeneratedCourse {
  title: string;
  description: string;
  summary: string;
  imageUrl?: string;
  objectives: string[];
  lessons: GeneratedLesson[];
  quiz?: GeneratedQuiz;
}








