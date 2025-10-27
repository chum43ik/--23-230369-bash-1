#!/bin/bash

# --- 1. Константы и метаданные ---
AUTHOR="Иванов Даниил"
PROGRAM_NAME="Проверка индексного дескриптора (inode)"
DESCRIPTION="Проверяет, изменялся ли inode указанного файла после заданной даты."
EXIT_ERROR_CODE=120
EXIT_INCORRECT_CODE=321

# --- 2. Функции ---

# Функция для вывода ошибок в поток stderr
error_message() {
    echo -e "\n> Ошибка! $1" >&2  # Перенаправляем в дескриптор 2 (stderr)
    LAST_ERROR=true
}

# Функция для проверки формата даты (простая проверка YYYY-MM-DD)
validate_date() {
    # Проверяем, соответствует ли строка формату YYYY-MM-DD
    if [[ ! "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        error_message "Дата должна быть в формате YYYY-MM-DD (например, 2024-01-30)."
        return 1
    fi

    # Дополнительно можно проверить валидность даты, но это усложнит Bash
    # Для целей ЛР достаточно проверки формата.
    return 0
}


# --- 3. Основной диалог программы ---
run_program() {
    local FILE_NAME=""
    local INPUT_DATE=""
    
    # 1. Вывод текущего каталога
    echo -e "\n--- Начало выполнения ---\n"
    echo -e "Текущий рабочий каталог: $(pwd)"

    # --- Диалог 1: Запрос имени файла ---
    while true; do
        echo -e "\n> Введите имя файла для проверки:"
        read -r FILE_NAME
        
        # Обработка ошибки: файл не существует
        if [[ ! -f "$FILE_NAME" ]]; then
            error_message "Файл '$FILE_NAME' не существует или это не обычный файл."
            continue
        fi
        break
    done

    # --- Диалог 2: Запрос даты ---
    while true; do
        echo -e "\n> Введите дату (формат YYYY-MM-DD) для сравнения:"
        read -r INPUT_DATE
        
        # Обработка ошибки: некорректный формат даты
        if ! validate_date "$INPUT_DATE"; then
            continue
        fi
        break
    done

    # --- 4. Логика проверки inode ---

    # Используем команду find с оператором -cnewer
    # -cnewer FILE: проверяет, был ли индексный дескриптор файла изменен после FILE
    # Чтобы использовать дату, мы сначала создадим временный файл с этой датой.

    TEMP_FILE=$(mktemp) # Создаем временный файл
    touch -t "$(date -d "$INPUT_DATE" +%Y%m%d0000.00)" "$TEMP_FILE" 2>/dev/null
    
    # Проверяем код возврата 'touch'. Если дата невалидна, 'touch' вернет ошибку.
    if [[ $? -ne 0 ]]; then
        rm -f "$TEMP_FILE" # Удаляем temp-файл
        error_message "Невозможно обработать дату '$INPUT_DATE'. Возможно, это невалидная дата (например, 2024-02-30)."
        return 1
    fi
    
    # Теперь ищем файл, чей inode был изменен позже, чем дата создания TEMP_FILE
    
    # Используем find, чтобы проверить, удовлетворяет ли наш файл условию
    # -cnewer (изменение inode)
    # -quit (завершение после первого совпадения)
    
    # Запуск find в подпроцессе, сохраняем его результат (0 или 1)
    find "$FILE_NAME" -type f -cnewer "$TEMP_FILE" -quit 2>/dev/null
    FIND_RESULT=$?
    
    # Очистка
    rm -f "$TEMP_FILE"

    # Анализ результата
    if [[ $FIND_RESULT -eq 0 ]]; then
        # Код возврата find 0 означает, что элемент найден (условие -cnewer выполнено)
        echo -e "\n> ИНДЕКСНЫЙ ДЕСКРИПТОР файла '$FILE_NAME' ИЗМЕНЯЛСЯ после $INPUT_DATE."
        return $EXIT_ERROR_CODE
    else
        # Код возврата find > 0 означает, что элемент не найден
        echo -e "\n> ИНДЕКСНЫЙ ДЕСКРИПТОР файла '$FILE_NAME' НЕ ИЗМЕНЯЛСЯ после $INPUT_DATE."
        return 0
    fi
}

# --- 5. Основной бесконечный цикл ---

# Вывод метаданных при первом запуске
echo "========================================="
echo "Программа: $PROGRAM_NAME"
echo "Разработчик: $AUTHOR"
echo "$DESCRIPTION"
echo "========================================="
echo -e "\n> Хотите начать выполнение программы? (y/n)"
read -r START_CHOICE

if [[ ! "$START_CHOICE" =~ ^[Yy]$ ]]; then
    exit 0
fi

while true; do
    LAST_ERROR=false # Флаг для отслеживания ошибок в последнем выполнении
    
    # Запускаем основную логику и сохраняем код возврата
    run_program
    RETURN_CODE=$?
    
    # Проверка, был ли возврат с ошибкой (кроме специальных кодов)
    if [[ $RETURN_CODE -ne 0 ]] && [[ $RETURN_CODE -ne $EXIT_ERROR_CODE ]]; then
        LAST_ERROR=true
        error_message "Внутренняя ошибка выполнения. Код $RETURN_CODE."
    fi

    # Проверка кода, требующего немедленного выхода
    if [[ $RETURN_CODE -eq $EXIT_ERROR_CODE ]]; then
        echo -e "\n--- Программа завершается с кодом $EXIT_ERROR_CODE по требованию задания. ---"
        exit $EXIT_ERROR_CODE
    fi
    
    # --- Выход из цикла / Повтор ---
    echo -e "\n> Хотите продолжить? (y/n)"
    read -r CONTINUE_CHOICE
    
    if [[ ! "$CONTINUE_CHOICE" =~ ^[Yy]$ ]]; then
        if $LAST_ERROR; then
            echo -e "\n--- Программа завершена (последнее выполнение с ошибкой: код $EXIT_INCORRECT_CODE). ---"
            exit $EXIT_INCORRECT_CODE
        else
            echo -e "\n--- Программа завершена. ---"
            exit 0
        fi
    fi
done

# Конец скрипта