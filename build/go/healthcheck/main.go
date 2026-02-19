package main

import (
	"os"
	"context"
	"time"
	"errors"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func connectMongo(ctx context.Context) (*mongo.Client, error) {
	clientOptions := options.Client().ApplyURI("mongodb://localhost:27017")
	client, err := mongo.Connect(ctx, clientOptions)
	if err != nil {
		return nil, err
	}

	if err := client.Ping(ctx, nil); err != nil {
		return nil, err
	}

	return client, nil
}

func IsOK() (bool, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	client, err := connectMongo(ctx)
	if err != nil {
		return false, err
	}
	defer client.Disconnect(ctx)

	var result bson.M
	err = client.Database("admin").RunCommand(
		ctx,
		bson.D{{Key: "dbStats", Value: 1}},
	).Decode(&result)

	if err != nil {
		return false, err
	}

	okValue, exists := result["ok"]
	if !exists {
		return false, errors.New("no dbStats found")
	}

	if okFloat, ok := okValue.(float64); ok && okFloat == 1 {
		return true, nil
	}

	return false, nil
}

func main() {
	if ok, _ := IsOK(); ok {
		os.Exit(0)
	}
	os.Exit(1)
}