package main

import (
	"testing"
)

func TestNewUser(t *testing.T) {
	tests := []struct {
		name     string
		id       int
		username string
		email    string
		wantErr  bool
	}{
		{
			name:     "valid user",
			id:       1,
			username: "testuser",
			email:    "test@example.com",
			wantErr:  false,
		},
		{
			name:     "invalid id",
			id:       0,
			username: "testuser",
			email:    "test@example.com",
			wantErr:  true,
		},
		{
			name:     "empty username",
			id:       1,
			username: "",
			email:    "test@example.com",
			wantErr:  true,
		},
		{
			name:     "empty email",
			id:       1,
			username: "testuser",
			email:    "",
			wantErr:  true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			user, err := NewUser(tt.id, tt.username, tt.email)
			
			if tt.wantErr {
				if err == nil {
					t.Errorf("NewUser() expected error, got nil")
				}
				return
			}
			
			if err != nil {
				t.Errorf("NewUser() unexpected error: %v", err)
				return
			}
			
			if user.GetID() != tt.id {
				t.Errorf("GetID() = %v, want %v", user.GetID(), tt.id)
			}
			if user.GetUsername() != tt.username {
				t.Errorf("GetUsername() = %v, want %v", user.GetUsername(), tt.username)
			}
			if user.GetEmail() != tt.email {
				t.Errorf("GetEmail() = %v, want %v", user.GetEmail(), tt.email)
			}
		})
	}
}

func TestUpdateEmail(t *testing.T) {
	user, err := NewUser(1, "testuser", "old@example.com")
	if err != nil {
		t.Fatalf("Failed to create user: %v", err)
	}

	// Test valid email update
	err = user.UpdateEmail("new@example.com")
	if err != nil {
		t.Errorf("UpdateEmail() unexpected error: %v", err)
	}
	if user.GetEmail() != "new@example.com" {
		t.Errorf("GetEmail() = %v, want %v", user.GetEmail(), "new@example.com")
	}

	// Test invalid email update
	err = user.UpdateEmail("")
	if err == nil {
		t.Errorf("UpdateEmail() expected error for empty email, got nil")
	}
	// Email should remain unchanged
	if user.GetEmail() != "new@example.com" {
		t.Errorf("GetEmail() = %v, want %v after failed update", user.GetEmail(), "new@example.com")
	}
}

func TestUserString(t *testing.T) {
	user, err := NewUser(123, "johndoe", "john@example.com")
	if err != nil {
		t.Fatalf("Failed to create user: %v", err)
	}

	expected := "User{ID: 123, Username: johndoe, Email: john@example.com}"
	result := user.String()
	if result != expected {
		t.Errorf("String() = %v, want %v", result, expected)
	}
}