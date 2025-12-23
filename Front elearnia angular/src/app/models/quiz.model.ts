export interface Question {
  id: number;
  text: string;
  options: string[];
  correctAnswer: string;
  points: number;
}

export interface Quiz {
  id: number;
  title: string;
  description: string;
  passingScore: number;
  maxAttempts: number;
  remainingAttempts: number;
  level?: string; // BEGINNER, INTERMEDIATE, ADVANCED
  courseId?: number;
  questions: Question[];
}

export interface QuizSummary {
  id: number;
  title: string;
  description: string;
  passingScore: number;
  maxAttempts: number;
  remainingAttempts: number;
  level: string;
  questionCount: number;
}

export interface QuizResult {
  score: number; // Score en pourcentage
  passed: boolean; // true si score >= passingScore
  attemptNumber: number; // Numéro de la tentative
  remainingAttempts: number; // Tentatives restantes
  courseCompleted?: boolean; // true si le cours est maintenant complété
  totalQuestions?: number; // Pour compatibilité
  correctAnswers?: number; // Pour compatibilité (calculé côté frontend si nécessaire)
  message?: string; // Message optionnel
}



