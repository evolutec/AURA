use crate::types::{ChatMessage, Role};

/// A chat session: ordered messages (optionally seeded with a system prompt).
#[derive(Debug, Clone)]
pub struct ChatSession {
    pub messages: Vec<ChatMessage>,
}

impl ChatSession {
    pub fn new(system_prompt: Option<String>) -> Self {
        let mut messages = Vec::new();
        if let Some(s) = system_prompt {
            if !s.is_empty() {
                messages.push(ChatMessage { role: Role::System, content: s });
            }
        }
        Self { messages }
    }

    pub fn push_user(&mut self, content: impl Into<String>) {
        self.messages.push(ChatMessage { role: Role::User, content: content.into() });
    }

    pub fn push_assistant(&mut self, content: impl Into<String>) {
        self.messages.push(ChatMessage { role: Role::Assistant, content: content.into() });
    }

    pub fn push_tool(&mut self, content: impl Into<String>) {
        self.messages.push(ChatMessage { role: Role::Tool, content: content.into() });
    }
}
