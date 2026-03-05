package org.delcom.repositories

import org.delcom.entities.Todo

interface  ITodoRepository {
    suspend fun getAll(
        userId: String,
        search: String,
        isDone: Boolean?,
        page: Int,
        perPage: Int
    ): Pair<List<Todo>, Long>
    suspend fun getSummary(userId: String): Triple<Long, Long, Long>
    suspend fun getById(todoId: String): Todo?
    suspend fun create(todo: Todo): String
    suspend fun update(userId: String, todoId: String, newTodo: Todo): Boolean
    suspend fun delete(userId: String, todoId: String) : Boolean
}
