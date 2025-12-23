import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { ChatMessage } from '../models/chat-message.model';

@Injectable({
  providedIn: 'root'
})
export class ChatbotService {
  private readonly baseUrl = 'http://localhost:8080';

  constructor(private http: HttpClient) {}

  sendMessage(message: string): Observable<string> {
    return this.http.post<{ response: string }>(`${this.baseUrl}/student/chatbot/message`, {
      message
    }).pipe(
      map(response => response.response)
    );
  }
}

