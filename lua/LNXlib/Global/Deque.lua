Deque = {
    _items = {},
    _size = 0
}
Deque.__index = Deque
setmetatable(Deque, Deque)

function Deque.new(items)
    local self = setmetatable({}, Deque)
    self._items = items or {}
    self._size = #self._items

    return self
end

function Deque:pushFront(item)
    table.insert(self._items, 1, item)
    self._size = self._size + 1
end

function Deque:pushBack(item)
    self._size = self._size + 1
    self._items[self._size] = item
end

function Deque:popFront()
    self._size = self._size - 1
    return table.remove(self._items, 1)
end

function Deque:popBack()
    self._size = self._size - 1
    return table.remove(self._items)
end

function Deque:peekFront()
    return self._items[1]
end

function Deque:peekBack()
    return self._items[self._size]
end

function Deque:empty()
    return self._size == 0
end

function Deque:clear()
    self._items = {}
    self._size = 0
end

function Deque:size()
    return self._size
end

function Deque:items()
    return table.readOnly(self._items)
end
