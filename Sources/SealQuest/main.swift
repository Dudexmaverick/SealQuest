
import Gtk
import Foundation

// MARK: - SEAL QUEST
// A Jornada ao Santuário

// MARK: - Estado do jogo

final class GameState {
    let size = 5

    var playerX = 2
    var playerY = 4

    var fishX = 2
    var fishY = 1

    var level = 1
    var score = 0
    var lives = 3
    var finished = false

    var trash: [(Int, Int)] = [
        (1, 2),
        (3, 3),
        (0, 1)
    ]

    func resetLevel() {
        playerX = 2
        playerY = 4

        fishX = 2
        fishY = 1

        trash = [
            (1, 2),
            (3, 3),
            (0, 1)
        ]

        if level >= 2 {
            trash.append((4, 2))
        }

        if level >= 3 {
            trash.append((0, 3))
        }
    }

    func move(dx: Int, dy: Int) -> String {
        if finished {
            return "A aventura terminou! Reinicie para jogar."
        }

        let nextX = max(
            0,
            min(size - 1, playerX + dx)
        )

        let nextY = max(
            0,
            min(size - 1, playerY + dy)
        )

        playerX = nextX
        playerY = nextY

        // Colisão com lixo
        let collision = trash.contains {
            $0.0 == playerX && $0.1 == playerY
        }

        if collision {
            lives -= 1

            if lives <= 0 {
                finished = true
                return "💔 Fim de jogo! Tente novamente."
            }

            playerX = 2
            playerY = 4

            return "⚠️ Cuidado com o lixo! Você perdeu uma vida."
        }

        // Coletar peixinho
        if playerX == fishX && playerY == fishY {
            score += 1

            // Avançar de nível
            if score >= level * 3 {
                if level >= 3 {
                    finished = true

                    return "🏝️ Vitória! Você chegou ao Santuário das Focas!"
                }

                level += 1
                resetLevel()

                return "🎉 Parabéns! Bem-vinda ao nível \(level)!"
            }

            // Novo peixinho
            let positions = [
                (4, 0),
                (0, 0),
                (2, 1),
                (4, 4),
                (0, 4),
                (3, 0),
                (1, 4)
            ]

            for position in positions {
                let occupied = trash.contains {
                    $0.0 == position.0 &&
                    $0.1 == position.1
                }

                let playerHere =
                    position.0 == playerX &&
                    position.1 == playerY

                if !occupied && !playerHere {
                    fishX = position.0
                    fishY = position.1
                    break
                }
            }

            return "🐟 Peixinho coletado! Continue nadando!"
        }

        return "🌊 Continue nadando, pequena foca!"
    }

    func symbol(x: Int, y: Int) -> String {
        if playerX == x && playerY == y {
            return "🦭"
        }

        if fishX == x && fishY == y {
            return "🐟"
        }

        let isTrash = trash.contains {
            $0.0 == x && $0.1 == y
        }

        if isTrash {
            return level >= 2 ? "🗑️" : "🥤"
        }

        return "🌊"
    }

    func restart() {
        level = 1
        score = 0
        lives = 3
        finished = false

        resetLevel()
    }
}

// MARK: - Interface gráfica

let status = Application.run(startupHandler: nil) { app in

    let game = GameState()

    // Janela
    let window = ApplicationWindowRef(application: app)

    window.title = "Seal Quest — A Jornada ao Santuário"

    window.setDefaultSize(
        width: 560,
        height: 700
    )

    // Layout principal
    let layout = BoxRef(
        orientation: .vertical,
        spacing: 14
    )

    // Título
    let title = LabelRef(
        str: "🦭 SEAL QUEST"
    )
    layout.append(child: title)

    // Subtítulo
    let subtitle = LabelRef(
        str: "A Jornada ao Santuário"
    )
    layout.append(child: subtitle)

    // Informações
    let info = LabelRef(
        str: "❤️❤️❤️ | 🐟 0 pontos | Nível 1"
    )
    layout.append(child: info)

    // MARK: - Oceano

    let ocean = BoxRef(
        orientation: .vertical,
        spacing: 8
    )

    var cells: [[LabelRef]] = []

    for y in 0..<game.size {
        let row = BoxRef(
            orientation: .horizontal,
            spacing: 8
        )

        row.set(homogeneous: true)
        row.setHexpand(expand: true)

        var cellRow: [LabelRef] = []

        for x in 0..<game.size {
            let cell = LabelRef(
                str: game.symbol(x: x, y: y)
            )

            cell.setSizeRequest(
                width: 65,
                height: 65
            )

            row.append(child: cell)
            cellRow.append(cell)
        }

        ocean.append(child: row)
        cells.append(cellRow)
    }

    layout.append(child: ocean)

    // Mensagem
    let message = LabelRef(
        str: "💙 Ajude a foca a encontrar o santuário!"
    )
    layout.append(child: message)

    // MARK: - Atualizar interface

    func refresh(_ notice: String) {
        for y in 0..<game.size {
            for x in 0..<game.size {
                let symbol = game.symbol(x: x, y: y)

                symbol.withCString { text in
                    cells[y][x].setText(str: text)
                }
            }
        }

        let hearts = String(
            repeating: "❤️",
            count: max(0, game.lives)
        )

        let stats =
            "\(hearts) | 🐟 \(game.score) pontos | Nível \(game.level)"

        stats.withCString { text in
            info.setText(str: text)
        }

        notice.withCString { text in
            message.setText(str: text)
        }
    }

    // MARK: - Botões de movimento

    func createMoveButton(
        _ symbol: String,
        dx: Int,
        dy: Int
    ) -> ButtonRef {

        let button = ButtonRef(label: symbol)

        button.setSizeRequest(
            width: 90,
            height: 55
        )

        button.onClicked { _ in
            let notice = game.move(
                dx: dx,
                dy: dy
            )

            refresh(notice)
        }

        return button
    }

    // MARK: - Controles

    let controls = BoxRef(
        orientation: .vertical,
        spacing: 8
    )

    let upRow = BoxRef(
        orientation: .horizontal,
        spacing: 8
    )

    upRow.append(
        child: createMoveButton(
            "⬆️",
            dx: 0,
            dy: -1
        )
    )

    controls.append(child: upRow)

    let directions = BoxRef(
        orientation: .horizontal,
        spacing: 8
    )

    directions.append(
        child: createMoveButton(
            "⬅️",
            dx: -1,
            dy: 0
        )
    )

    directions.append(
        child: createMoveButton(
            "⬇️",
            dx: 0,
            dy: 1
        )
    )

    directions.append(
        child: createMoveButton(
            "➡️",
            dx: 1,
            dy: 0
        )
    )

    controls.append(child: directions)
    layout.append(child: controls)

    // MARK: - Reiniciar aventura

    let restart = ButtonRef(
        label: "🔄 Reiniciar aventura"
    )

    restart.onClicked { _ in
        game.restart()

        refresh(
            "🦭 Uma nova aventura começou!"
        )
    }

    layout.append(child: restart)

    // Exibir jogo
    window.set(child: layout)
    window.set(visible: true)
}

print(
    "Seal Quest encerrado: \(String(describing: status))"
)
