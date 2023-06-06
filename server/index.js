const Redis = require("ioredis");
const redisClient = new Redis();
const { Server } = require("socket.io");
const express = require("express");
const http = require("http");
const app = express();
const server = http.createServer(app);
const io = new Server(server);
const { v4: uuidv4 } = require("uuid");
const Joi = require("joi");

const messageSchema = Joi.object({
  username: Joi.string().min(3).max(30).required(),
  message: Joi.string().min(1).max(500).required(),
});

io.on("connection", async (socket) => {
  console.log("Connected");
  const existingMessage = await redisClient.lrange("chat_messages", 0, -1);
  const parserMessages = existingMessage.map((item) => JSON.parse(item));
  socket.emit("messages", parsedMessages);
  socket.on("message", (data) => {
    console.log(data);
    const { value, error } = messageSchema.validate(data);
    if (error) {
      console.log("Invalid message, error occurred", error);
      socket.emit("error", error);
      return;
    }
    const newMessage = {
      id: uuidv4,
      username: value.username,
      message: value.message,
      created: new Date().getTime(),
    };
    redisClient.lpush("chat_messages", JSON.stringify(newMessage));

    io.emit("message", newMessage);
  });
});

server.listen(3000, () => {
  console.log("Server is running on port : 3000");
});
