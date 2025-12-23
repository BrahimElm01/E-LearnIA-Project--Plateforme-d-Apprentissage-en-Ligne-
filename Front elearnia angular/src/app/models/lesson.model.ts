export interface Lesson {
  id: number;
  title: string;
  description?: string;
  videoUrl: string | null; // Peut être null pour les leçons sans vidéo
  duration?: number; // en minutes
  orderIndex: number;
}








