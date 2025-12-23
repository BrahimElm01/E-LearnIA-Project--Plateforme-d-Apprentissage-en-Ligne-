import { Component, signal, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';

interface FeatureSlide {
  id: number;
  title: string;
  subtitle: string;
  description: string;
  buttonText: string;
  buttonRoute: string[];
  gradient: string;
  icon: string;
  image?: string;
  features: string[];
}

@Component({
  selector: 'app-features-carousel',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './features-carousel.component.html',
  styleUrl: './features-carousel.component.css'
})
export class FeaturesCarouselComponent implements OnInit, OnDestroy {
  currentSlide = signal<number>(0);
  private autoPlayInterval: any;
  
  slides: FeatureSlide[] = [
    {
      id: 1,
      title: 'Apprentissage Interactif',
      subtitle: 'Maîtrisez de nouvelles compétences',
      description: 'Suivez des cours structurés avec des leçons vidéo, des quiz interactifs et un suivi de progression en temps réel.',
      buttonText: 'Explorer les cours →',
      buttonRoute: ['/student/courses'],
      gradient: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      icon: '📚',
      image: 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=800&q=80',
      features: ['Vidéos HD', 'Quiz interactifs', 'Progression suivie']
    },
    {
      id: 2,
      title: 'Quiz et Évaluations',
      subtitle: 'Testez vos connaissances',
      description: 'Passez des quiz adaptés à votre niveau et recevez des feedbacks instantanés pour améliorer votre apprentissage.',
      buttonText: 'Voir les quiz →',
      buttonRoute: ['/student/quizzes'],
      gradient: 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)',
      icon: '📝',
      image: 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=800&q=80',
      features: ['Niveaux adaptés', 'Feedback instantané', 'Tentatives multiples']
    },
    {
      id: 3,
      title: 'Analyses Détaillées',
      subtitle: 'Suivez votre progression',
      description: 'Visualisez vos statistiques d\'apprentissage, vos cours complétés et votre progression globale avec des graphiques détaillés.',
      buttonText: 'Voir les analyses →',
      buttonRoute: ['/student/analytics'],
      gradient: 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)',
      icon: '📊',
      image: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800&q=80',
      features: ['Statistiques détaillées', 'Graphiques visuels', 'Suivi de progression']
    },
    {
      id: 4,
      title: 'IA Assistante',
      subtitle: 'Votre assistant d\'apprentissage',
      description: 'Posez des questions à notre chatbot IA pour obtenir de l\'aide, des explications et des recommandations personnalisées.',
      buttonText: 'Essayer le chatbot →',
      buttonRoute: ['/student/chatbot'],
      gradient: 'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)',
      icon: '🤖',
      image: 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800&q=80',
      features: ['Réponses instantanées', 'Aide personnalisée', '24/7 disponible']
    }
  ];

  constructor(private router: Router) {}

  ngOnInit(): void {
    // Auto-play : changer de slide toutes les 5 secondes
    this.autoPlayInterval = setInterval(() => {
      this.nextSlide();
    }, 5000);
  }

  ngOnDestroy(): void {
    if (this.autoPlayInterval) {
      clearInterval(this.autoPlayInterval);
    }
  }

  get currentSlideData(): FeatureSlide {
    return this.slides[this.currentSlide()];
  }

  nextSlide(): void {
    const next = (this.currentSlide() + 1) % this.slides.length;
    this.currentSlide.set(next);
    this.resetAutoPlay();
  }

  previousSlide(): void {
    const prev = (this.currentSlide() - 1 + this.slides.length) % this.slides.length;
    this.currentSlide.set(prev);
    this.resetAutoPlay();
  }

  goToSlide(index: number): void {
    this.currentSlide.set(index);
    this.resetAutoPlay();
  }

  private resetAutoPlay(): void {
    if (this.autoPlayInterval) {
      clearInterval(this.autoPlayInterval);
    }
    this.autoPlayInterval = setInterval(() => {
      this.nextSlide();
    }, 5000);
  }

  navigateToFeature(route: string[]): void {
    this.router.navigate(route);
  }
}

