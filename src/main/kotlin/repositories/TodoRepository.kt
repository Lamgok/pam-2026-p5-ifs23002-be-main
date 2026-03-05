package org.delcom.repositories

import org.delcom.dao.TodoDAO
import org.delcom.entities.Todo
import org.delcom.helpers.suspendTransaction
import org.delcom.helpers.todoDAOToModel
import org.delcom.tables.TodoTable
import org.jetbrains.exposed.sql.SortOrder
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.SqlExpressionBuilder.like
import org.jetbrains.exposed.sql.and
import org.jetbrains.exposed.sql.deleteWhere
import org.jetbrains.exposed.sql.lowerCase
import org.jetbrains.exposed.sql.or
import java.util.*

class TodoRepository : ITodoRepository {
    override suspend fun getAll(
        userId: String,
        search: String,
        isDone: Boolean?,
        page: Int,
        perPage: Int
    ): Pair<List<Todo>, Long> = suspendTransaction {
        val userUUID = UUID.fromString(userId)
        var filters = TodoTable.userId eq userUUID

        if (search.isNotBlank()) {
            val keyword = "%${search.lowercase()}%"
            filters = filters and (
                (TodoTable.title.lowerCase() like keyword) or
                    (TodoTable.description.lowerCase() like keyword)
            )
        }

        if (isDone != null) {
            filters = filters and (TodoTable.isDone eq isDone)
        }

        val query = TodoDAO.find { filters }
        val totalItems = query.count()
        val offset = ((page - 1) * perPage).toLong()
        val todos = query
            .orderBy(TodoTable.createdAt to SortOrder.DESC)
            .limit(perPage)
            .offset(offset)
            .map(::todoDAOToModel)

        Pair(todos, totalItems)
    }

    override suspend fun getSummary(userId: String): Triple<Long, Long, Long> = suspendTransaction {
        val userUUID = UUID.fromString(userId)
        val totalTodos = TodoDAO.find { TodoTable.userId eq userUUID }.count()
        val totalDoneTodos = TodoDAO.find {
            (TodoTable.userId eq userUUID) and (TodoTable.isDone eq true)
        }.count()
        val totalUndoneTodos = totalTodos - totalDoneTodos

        Triple(totalTodos, totalDoneTodos, totalUndoneTodos)
    }

    override suspend fun getById(todoId: String): Todo? = suspendTransaction {
        TodoDAO
            .find {
                (TodoTable.id eq UUID.fromString(todoId))
            }
            .limit(1)
            .map(::todoDAOToModel)
            .firstOrNull()
    }

    override suspend fun create(todo: Todo): String = suspendTransaction {
        val todoDAO = TodoDAO.new {
            userId = UUID.fromString(todo.userId)
            title = todo.title
            description = todo.description
            cover = todo.cover
            isDone = todo.isDone
            createdAt = todo.createdAt
            updatedAt = todo.updatedAt
        }

        todoDAO.id.value.toString()
    }

    override suspend fun update(userId: String, todoId: String, newTodo: Todo): Boolean = suspendTransaction {
        val todoDAO = TodoDAO
            .find {
                (TodoTable.id eq UUID.fromString(todoId)) and
                        (TodoTable.userId eq UUID.fromString(userId))
            }
            .limit(1)
            .firstOrNull()

        if (todoDAO != null) {
            todoDAO.title = newTodo.title
            todoDAO.description = newTodo.description
            todoDAO.cover = newTodo.cover
            todoDAO.isDone = newTodo.isDone
            todoDAO.updatedAt = newTodo.updatedAt
            true
        } else {
            false
        }
    }

    override suspend fun delete(userId: String, todoId: String): Boolean = suspendTransaction {
        val rowsDeleted = TodoTable.deleteWhere {
            (TodoTable.id eq UUID.fromString(todoId)) and
                    (TodoTable.userId eq UUID.fromString(userId))
        }
        rowsDeleted >= 1
    }

}
