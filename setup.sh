#!/bin/bash

# Project setup
PROJECT_DIR="gameportal"
GAME_NAME="circle_mover"

# Create directory structure
mkdir -p $PROJECT_DIR/{static/{games/$GAME_NAME,images},templates,game_folder}
cd $PROJECT_DIR

# Create Flask app
cat > app.py << 'EOF'
from flask import Flask, render_template

app = Flask(__name__)

@app.route('/')
def home():
    games = [
        {
            'title': 'Circle Mover',
            'description': 'Move a red circle with WASD keys!',
            'url': '/static/games/circle_mover/index.html',
            'screenshot': '/static/images/circle_mover_screenshot.png'
        }
    ]
    return render_template('index.html', games=games)

if __name__ == '__main__':
    app.run(debug=True)
EOF

# Create HTML template
mkdir -p templates
cat > templates/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GamePortal</title>
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
</head>
<body class="bg-gray-100">
    <div class="container mx-auto p-4">
        <h1 class="text-3xl font-bold text-center mb-6">GamePortal</h1>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {% for game in games %}
            <div class="bg-white p-4 rounded-lg shadow-md">
                <h2 class="text-xl font-semibold">{{ game.title }}</h2>
                <p class="text-gray-600 mb-2">{{ game.description }}</p>
                <img src="{{ game.screenshot }}" alt="{{ game.title }} screenshot" class="w-full h-48 object-cover mb-2 rounded">
                <a href="{{ game.url }}" target="_blank" class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600">Play Now</a>
            </div>
            {% endfor %}
        </div>
    </div>
</body>
</html>
EOF

# Create Pygame game
cd game_folder
cat > main.py << 'EOF'
import pygame
import asyncio
import platform

# Pygame setup
pygame.init()
screen = pygame.display.set_mode((800, 600))
clock = pygame.time.Clock()
player_pos = pygame.Vector2(screen.get_width() / 2, screen.get_height() / 2)
FPS = 60

async def main():
    running = True
    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False

        # Player movement
        keys = pygame.key.get_pressed()
        if keys[pygame.K_w]:
            player_pos.y -= 300 * (1.0 / FPS)
        if keys[pygame.K_s]:
            player_pos.y += 300 * (1.0 / FPS)
        if keys[pygame.K_a]:
            player_pos.x -= 300 * (1.0 / FPS)
        if keys[pygame.K_d]:
            player_pos.x += 300 * (1.0 / FPS)

        # Render
        screen.fill("black")
        pygame.draw.circle(screen, "red", player_pos, 20)
        pygame.display.flip()
        clock.tick(FPS)
        await asyncio.sleep(0)  # Required for Pygbag

    pygame.quit()

if platform.system() == "Emscripten":
    asyncio.ensure_future(main())
else:
    if __name__ == "__main__":
        asyncio.run(main())
EOF

# Install dependencies
cd ..
python -m venv venv
source venv/bin/activate
pip install Flask gunicorn pygame pygbag
pip freeze > requirements.txt

# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
EOF

# Package game with Pygbag
cd game_folder
python -m pygbag --build .
cd ..
mkdir -p static/games/$GAME_NAME
cp -r game_folder/build/web/* static/games/$GAME_NAME/

# Create placeholder screenshot
touch static/images/circle_mover_screenshot.png

# Initialize Git and prepare for Render
git init
cat > .gitignore << 'EOF'
venv/
__pycache__/
*.pyc
EOF
git add .
git commit -m "Initial GamePortal setup"

# Display instructions
echo "Setup complete! To deploy to Render.com:"
echo "1. Create a new Web Service on Render.com."
echo "2. Connect your GitHub repo and push this project."
echo "3. Set Environment to 'Docker' and deploy."
echo "4. Add a placeholder screenshot at static/images/circle_mover_screenshot.png."
echo "Game will be playable at /static/games/circle_mover/index.html."