---
title: React
date: 2024-10-22 21:41:32
tags:
- "React"
id: react
no_word_count: true
no_toc: false
categories: 
- "前端"
---

## React

### 简介

做 Next.js 的时候发现基础还是要看看。

### 初步试用

井字棋练习题完整版：

```javascript
import { useState } from 'react';

function Square({ value, onSquareClick, isWinningSquare }) {
    const backgroundColor = isWinningSquare ? 'yellow' : 'white';
    return (
        <button
            className="square"
            onClick={onSquareClick}
            style={{ backgroundColor }}
        >
            {value}
        </button>
    );
}

function Board({ xIsNext, squares, onPlay, winningSquares }) {
    function handleClick(i) {
        if (calculateWinner(squares) || squares[i]) {
            return;
        }
        const nextSquares = squares.slice();
        if (xIsNext) {
            nextSquares[i] = 'X';
        } else {
            nextSquares[i] = 'O';
        }
        onPlay(nextSquares, i);
    }

    const winner = calculateWinner(squares)?.winner;
    const isDraw = !winner && squares.every(Boolean);

    let status;
    if (winner) {
        status = 'Winner: ' + winner;
    } else if (isDraw) {
        status = "It's a draw!";
    } else {
        status = 'Next player: ' + (xIsNext ? 'X' : 'O');
    }

    return (
        <>
            <div className="status">{status}</div>
            {Array(3).fill(null).map((_, rowIndex) => (
                <div className="board-row" key={rowIndex}>
                    {Array(3).fill(null).map((_, colIndex) => {
                        const index = rowIndex * 3 + colIndex;
                        return (
                            <Square
                                key={index}
                                value={squares[index]}
                                onSquareClick={() => handleClick(index)}
                                isWinningSquare={winningSquares?.includes(index)}
                            />
                        );
                    })}
                </div>
            ))}
        </>
    );
}

export default function Game() {
    const [history, setHistory] = useState([{ squares: Array(9).fill(null), position: null }]); // 记录落子位置
    const [currentMove, setCurrentMove] = useState(0);
    const [isAscending, setIsAscending] = useState(true);
    const xIsNext = currentMove % 2 === 0;
    const currentSquares = history[currentMove].squares;

    function handlePlay(nextSquares, position) {
        const nextHistory = [...history.slice(0, currentMove + 1), { squares: nextSquares, position }];
        setHistory(nextHistory);
        setCurrentMove(nextHistory.length - 1);
    }

    function jumpTo(nextMove) {
        setCurrentMove(nextMove);
    }

    function toggleSortOrder() {
        setIsAscending(!isAscending);
    }

    const winnerInfo = calculateWinner(currentSquares);
    const winningSquares = winnerInfo ? winnerInfo.line : null;

    const sortedMoves = isAscending ? history : [...history].reverse();
    const moves = sortedMoves.map((entry, move) => {
        const totalMoves = history.length - 1;
        const adjustedMove = isAscending ? move : totalMoves - move;

        let description;
        if (adjustedMove === totalMoves && totalMoves !== 0) {
            description = `You are at move ${totalMoves}`;
        } else if (adjustedMove > 0) {
            const row = Math.ceil((entry.position + 1) / 3);
            const col = (entry.position + 1) - (row - 1) * 3;
            description = `Go to move #${adjustedMove} (row: ${row}, col: ${col})`;
        } else {
            description = 'Go to game start';
        }

        return (
            <li key={adjustedMove}>
                <button onClick={() => jumpTo(adjustedMove)}>{description}</button>
            </li>
        );
    });

    return (
        <div className="game">
            <div className="game-board">
                <Board
                    xIsNext={xIsNext}
                    squares={currentSquares}
                    onPlay={handlePlay}
                    winningSquares={winningSquares}
                />
            </div>
            <div className="game-info">
                <button onClick={toggleSortOrder}>
                    {isAscending ? 'Sort Descending' : 'Sort Ascending'}
                </button>
                <ol>{moves}</ol>
            </div>
        </div>
    );
}

function calculateWinner(squares) {
    const lines = [
        [0, 1, 2],
        [3, 4, 5],
        [6, 7, 8],
        [0, 3, 6],
        [1, 4, 7],
        [2, 5, 8],
        [0, 4, 8],
        [2, 4, 6],
    ];
    for (let i = 0; i < lines.length; i++) {
        const [a, b, c] = lines[i];
        if (squares[a] && squares[a] === squares[b] && squares[a] === squares[c]) {
            return { winner: squares[a], line: lines[i] };
        }
    }
    return null;
}
```

### 参考资料

[官方网站](https://react.dev/)

[井字棋教程](https://react.dev/learn/tutorial-tic-tac-toe)

[Awesome React](https://github.com/enaqx/awesome-react)

[HTML to JSX](https://transform.tools/html-to-jsx)
