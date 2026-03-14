package main

import (
	"fmt"
)

// Calculator provides basic arithmetic operations
type Calculator struct {
	lastResult int
}

// NewCalculator creates a new Calculator instance
func NewCalculator() *Calculator {
	return &Calculator{lastResult: 0}
}

// Add adds two numbers and stores the result
func (c *Calculator) Add(a, b int) int {
	c.lastResult = a + b
	return c.lastResult
}

// Subtract subtracts b from a and stores the result
func (c *Calculator) Subtract(a, b int) int {
	c.lastResult = a - b
	return c.lastResult
}

// Multiply multiplies two numbers and stores the result
func (c *Calculator) Multiply(a, b int) int {
	c.lastResult = a * b
	return c.lastResult
}

// Divide divides a by b and stores the result
// Returns error if b is zero
func (c *Calculator) Divide(a, b int) (int, error) {
	if b == 0 {
		return 0, fmt.Errorf("division by zero")
	}
	c.lastResult = a / b
	return c.lastResult, nil
}

// GetLastResult returns the last calculated result
func (c *Calculator) GetLastResult() int {
	return c.lastResult
}

// Reset resets the last result to zero
func (c *Calculator) Reset() {
	c.lastResult = 0
}

// String returns a string representation of the calculator
func (c *Calculator) String() string {
	return fmt.Sprintf("Calculator{LastResult: %d}", c.lastResult)
}