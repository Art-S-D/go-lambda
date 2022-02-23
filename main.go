package main

import (
	"fmt"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/go-playground/validator/v10"
)

type Event struct {
	Foo string `json:"foo" validate:"required"`
	Bar int    `json:"bar" validate:"required"`
}

type Response struct {
	Response string `json:"response"`
}

func LambdaHandler(event Event) (Response, error) {
	validate := validator.New()
	err := validate.Struct(event)
	if err != nil {
		return Response{Response: "Error"}, err
	}
	return Response{Response: fmt.Sprintf("foo:%s, bar:%d", event.Foo, event.Bar)}, nil
}

func main() {
	lambda.Start(LambdaHandler)
}
