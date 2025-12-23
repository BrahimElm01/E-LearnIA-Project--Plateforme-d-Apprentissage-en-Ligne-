import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ChatbotService } from '../../../services/chatbot.service';
import { ChatMessage } from '../../../models/chat-message.model';

@Component({
  selector: 'app-chatbot',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './chatbot.component.html',
  styleUrl: './chatbot.component.css'
})
export class ChatbotComponent implements OnInit {
  messages = signal<ChatMessage[]>([]);
  currentMessage = signal('');
  isLoading = signal(false);
  isOpen = signal(false);

  constructor(private chatbotService: ChatbotService) {}

  ngOnInit(): void {
    this.messages.set([{
      id: '1',
      text: 'Bonjour ! Je suis votre assistant IA. Comment puis-je vous aider ?',
      isUser: false,
      timestamp: new Date()
    }]);
  }

  toggleChat(): void {
    this.isOpen.update(open => !open);
    // Scroll vers le bas quand on ouvre le chat
    if (this.isOpen()) {
      setTimeout(() => {
        this.scrollToBottom();
      }, 100);
    }
  }

  closeChat(): void {
    this.isOpen.set(false);
  }

  scrollToBottom(): void {
    const container = document.querySelector('.messages-container');
    if (container) {
      container.scrollTop = container.scrollHeight;
    }
  }

  sendMessage(): void {
    const text = this.currentMessage().trim();
    if (!text || this.isLoading()) return;

    const userMessage: ChatMessage = {
      id: Date.now().toString(),
      text,
      isUser: true,
      timestamp: new Date()
    };

    this.messages.update(msgs => [...msgs, userMessage]);
    this.currentMessage.set('');
    this.isLoading.set(true);

    this.chatbotService.sendMessage(text).subscribe({
      next: (response) => {
        const botMessage: ChatMessage = {
          id: (Date.now() + 1).toString(),
          text: response || 'Désolé, je n\'ai pas pu générer de réponse.',
          isUser: false,
          timestamp: new Date()
        };
        this.messages.update(msgs => [...msgs, botMessage]);
        this.isLoading.set(false);
        setTimeout(() => this.scrollToBottom(), 100);
      },
      error: (error: any) => {
        console.error('Error sending message', error);
        console.error('Error details:', {
          status: error.status,
          message: error.message,
          error: error.error
        });
        
        // Afficher un message d'erreur à l'utilisateur
        const errorMessage: ChatMessage = {
          id: (Date.now() + 1).toString(),
          text: error.status === 401 
            ? 'Erreur d\'authentification. Veuillez vous reconnecter.'
            : error.status === 500
            ? 'Erreur serveur. Veuillez réessayer plus tard.'
            : 'Désolé, une erreur est survenue. Veuillez réessayer.',
          isUser: false,
          timestamp: new Date()
        };
        this.messages.update(msgs => [...msgs, errorMessage]);
        this.isLoading.set(false);
        setTimeout(() => this.scrollToBottom(), 100);
      }
    });
  }
}





