import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.util.fullScreen();
  runApp(MyGame().widget);
}

class Snake extends PositionComponent with HasGameRef<MyGame> {
  static const double tileSize = 22.0;
  static const double speed = tileSize;
  List<Vector2> body = [Vector2(0, 0)];

  Snake(Vector2 position) {
    this.position = position;
  }

  @override
  void render(Canvas c) {
    c.drawRect(Rect.fromLTWH(x, y, width, height), Paint()..color = const Color(0xFFFFFFFF));
    for (final segment in body.sublist(1)) {
      c.drawRect(Rect.fromLTWH(segment.x, segment.y, width, height), Paint()..color = const Color(0xFFFFFFFF));
    }
  }

  @override
  void update(double dt) {
    if (gameRef.snakeDirection != null) {
      move();
    }
  }

  void move() {
    final newHead = body.first.clone();
    switch (gameRef.snakeDirection) {
      case Direction.up:
        newHead.y -= speed;
        break;
      case Direction.down:
        newHead.y += speed;
        break;
      case Direction.left:
        newHead.x -= speed;
        break;
      case Direction.right:
        newHead.x += speed;
        break;
    }
    body.insert(0, newHead);

    if (newHead == gameRef.food.position) {
      gameRef.food.generatePosition();
      gameRef.score++;
    } else {
      body.removeLast();
    }

    if (checkCollision()) {
      gameRef.gameOver();
    }
  }

  bool checkCollision() {
    if (x < 0 || x >= gameRef.size.width || y < 0 || y >= gameRef.size.height) {
      return true; // Collision with walls
    }
    for (final segment in body.sublist(1)) {
      if (segment == body.first) {
        return true; // Collision with itself
      }
    }
    return false;
  }
}

class Food extends PositionComponent with HasGameRef<MyGame> {
  static const double size = 22.0;

  Food(Vector2 position) {
    this.position = position;
  }

  @override
  void render(Canvas c) {
    c.drawRect(Rect.fromLTWH(x, y, width, height), Paint()..color = const Color(0xFFFF0000));
  }

  void generatePosition() {
    final randomX = gameRef.random.nextDouble() * (gameRef.size.width - size);
    final randomY = gameRef.random.nextDouble() * (gameRef.size.height - size);
    position = Vector2(randomX, randomY);
  }
}

enum Direction { up, down, left, right }

class MyGame extends BaseGame {
  late Snake snake;
  late Food food;
  Direction? snakeDirection;
  late Size size;
  int score = 0;
  final random = Random();

  @override
  Future<void> onLoad() async {
    size = await Flame.util.initialDimensions();
    snake = Snake(Vector2(size.width / 2, size.height / 2));
    food = Food(Vector2(size.width / 3, size.height / 3));

    add(snake);
    add(food);

    Flame.util.addGestureRecognizer(TapGestureRecognizer()..onTapUp = (_) => onTap());
  }

  @override
  void update(double dt) {
    super.update(dt);
    snake.update(dt);
  }

  void onTap() {
    // Toggle the snake's direction on tap
    if (snakeDirection == Direction.up || snakeDirection == Direction.down) {
      snakeDirection = random.nextBool() ? Direction.left : Direction.right;
    } else {
      snakeDirection = random.nextBool() ? Direction.up : Direction.down;
    }
  }

  void gameOver() {
    // Handle game over logic
    print('Game Over! Score: $score');
    // You can add more logic like showing a game over screen, saving the score, etc.
    reset();
  }

  void reset() {
    // Reset the game state
    snake.body = [Vector2(size.width / 2, size.height / 2)];
    snakeDirection = null;
    food.generatePosition();
    score = 0;
  }
}
