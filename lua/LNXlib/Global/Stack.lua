Stack = {
    _items = {},
    _size = 0
}
Stack.__index = Stack
setmetatable(Stack, Stack)

function Stack.new(items)
    local self = setmetatable({}, Stack)
    self._items = items or {}
    self._size = #self._items

    return self
end

function Stack:push(item)
    self._size = self._size + 1
    self._items[self._size] = item
end

function Stack:pop()
    self._size = self._size - 1
    return table.remove(self._items)
end

function Stack:peek()
    return self._items[self._size]
end

function Stack:empty()
    return self._size == 0
end

function Stack:clear()
    self._items = {}
    self._size = 0
end

function Stack:size()
    return self._size
end

function Stack:items()
    return table.readOnly(self._items)
end
