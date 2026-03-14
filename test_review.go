// Package main contains test functions for code review
package main

import "fmt"

// User represents a user in the system
type User struct {
	ID       int
	Username string
	Email    string
}

// NewUser creates a new user with validation
func NewUser(id int, username, email string) (*User, error) {
	if id <= 0 {
		return nil, fmt.Errorf("invalid user ID: %d", id)
	}
	if username == "" {
		return nil, fmt.Errorf("username cannot be empty")
	}
	if email == "" {
		return nil, fmt.Errorf("email cannot be empty")
	}
	
	return &User{
		ID:       id,
		Username: username,
		Email:    email,
	}, nil
}

// GetID returns the user's ID
func (u *User) GetID() int {
	return u.ID
}

// GetUsername returns the user's username
func (u *User) GetUsername() string {
	return u.Username
}

// GetEmail returns the user's email
func (u *User) GetEmail() string {
	return u.Email
}

// UpdateEmail updates the user's email with validation
func (u *User) UpdateEmail(newEmail string) error {
	if newEmail == "" {
		return fmt.Errorf("email cannot be empty")
	}
	u.Email = newEmail
	return nil
}

// String returns a string representation of the user
func (u *User) String() string {
	return fmt.Sprintf("User{ID: %d, Username: %s, Email: %s}", 
		u.ID, u.Username, u.Email)
}