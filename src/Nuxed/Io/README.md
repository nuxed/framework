# The Nuxed Io Component

This repository is read-only. Please refer to the official framework repository for any issues or pull requests.

---

The IO component provides classes that interact with input and output of data on the local filesystem. Specialized classes can be used to read data, write data, alter permissions, rename files, copy, create, delete, move, traverse, and many more through an easy to use async interface.

---

## Installation

This package can be install with Composer.

```console
composer install nuxed/io
```

## Usage

```hack
$file = new Nuxed\Io\File('/path/to/file');
$folder = new Nuxed\Io\Folder('/path/to/folder');
```

Once an object is created, you can check if the file exists at the given path using `exists()`.

```hack
$folder->exists(); // false
```

### Creating & Deleting

Passing a boolean `true` as the 2nd argument to the constructor will automatically create the file if it does not exist. A permission mode can also be set as the 3rd argument.

```hack
$file = new File('/path/to/file', true);
$folder = new Folder('/path/to/folder', true, 0777);
```

If not using the constructor, use `create(): Awaitable<bool>`, which will return a boolean `true` on successful creation. This method will only create the file if it doesn't already exist. As well, an optional permission mode can be passed (defaults to `0755`).

```hack
await $file->create();
await $folder->create(0777);
```

To delete the file, use `delete(): Awaitable<bool>`, which will return a boolean `true` on successful deletion.

```hack
await $file->delete();
awwait $folder->delete();
```

<div class="notice is-warning">
    <b>Beware!</b> The <code>Folder</code> is atomic and will attempt to recursively delete all children before deleting itself.
</div>

### Copying, Moving & Renaming

Copying files can be tricky as you must validate the source and the destination. When copying with `copy(): Awaitable<bool>`, a destination path must be defined, and the type of operation to use ( value of `Nuxed\Io\OperationType` enum ).

* `OperationType::OVERWRITE` - Will overwrite the destination file if one exists (file and folder)
* `OperationType::MERGE` - Will merge folders together if they exist at the same location (folder only)
* `OperationType::SKIP` - Will not overwrite the destination file if it exists (file and folder)

An optional permission mode can be set as the 3rd argument for the newly copied file.

```hack
await $file->copy('/to/new/file', OperationType::OVERWRITE);
await $folder->copy('/to/new/folder', OperationType::MERGE, 0755);
```

Moving works in the same way as copying, but is much simpler. Simply use `move(): Awaitable<bool>` and pass the path to move to and a boolean on whether to overwrite the destination file if one exists (defaults `true`).

```hack
await $file->move('/to/new/path');
await $folder->move('/to/new/path', false);
```

Moving will only move a file, it will not rename a file. To rename a file in place, use `rename(): Awaitable<bool>`. This method requires a new name and a boolean on whether to overwrite the destination file (defaults `true`).

```hack
await $file->rename('new-file-name.' . $file->ext());
await $folder->rename('new-folder-name', false);
```

<div class="notice is-warning">
    Renaming does not handle file extensions. This should be handled manually.
</div>

### Informational

To access a file or folders name use `basename()`, or a file name without an extension use `name()`, or the extension itself use `ext()` (files only).

```hack
$file->basename(); // image.jpg
$file->name(); // image
$file->ext(); // jpg
```

To access the group, owner, or parent, use `group(): int`, `owner(): int`, and `parent(): ?Folder` respectively. The `parent(): ?Folder` method will return a new `Folder` instance for the folder that the file/folder belongs in. If there is no parent (at the root), `null` will be returned.

```hack
$file->group();
$file->owner();
$file->parent();
```

To get the size of a file, or the number of children within a folder, use `size(): Awaitable<int>`.

```hack
await $file->size();
await $folder->size();
```

### Timestamps

To access timestamps, like access, modified, and changed, use `accessTime(): int`, `modifyTime(): int`, and `changeTime(): int`.

```hack
$file->accessTime();
$file->modifyTime();
$file->changeTime();
```

### Permissions

To modify the group, owner, and mode, use `chgrp(): Awaitable<bool>`, `chown(): Awaitable<bool>`, and `chmod(): Awaitable<bool>` (requires an octal value).

```hack
await $file->chgrp(8);
await $file->chown(3);
await $file->chmod(0777);
```

To modify permissions on all files within a folder, set the recursive 2nd argument to `true`.

```hack
await $folder->chmod(0777, true);
```

The `permissions(): string` method will return the literal read-write-execute octal value.

```hack
$file->permissions(); // 0777
```

And to check if a file is `executable(): bool`, `readable(): bool`, and `writable(): bool`.

```hack
$file->executable(); // true
```

### Paths

The `path(): Path` method will return the current path while `dir(): Path` will return the parent folders path as an instance of `Nuxed\Io\Path`.

```hack
$path = $file->path();
$path = $file->dir();
```

To check if a path is relative or absolute, use `isRelative(): bool` or `isAbsolute(): bool` methods on the path instance, or use the node proxy.

```hack
if ($file->path()->isRelative()) {

}
// same as :
if ($file->isRelative()) {

}
```

## Files

`Nuxed\Io\File`s provide read, write functionality alongside the utility methods `mimeType()`, which attempts to guess the files type, and `md5()`, which returns an MD5 hash of the file.

```hack
$mime = $file->mimeType(); // text/html
$hash = $file->md5();
```

it also provides the ability to access the read and write handles of the current file.

```hack
await using ($handle = $file->getReadHandle()) {
  $content = await $handle->readAsync();
}

await using ($handle = $file->getWriteHandle()) {
  await $handle->writeAsync($content);
}
```

### Reading Files Content

The `read()` method will attempt to read the contents of the current file. An optional limit can be passed to return all bytes up until that point.

```hack
$content = await $file->read();
$content = await $file->read(1234);
```

This method will lock the file until the contents have been read.

### Writing To Files

The `write(): Awaitable<void>` method will write content to the current file. The default write [mode](https://github.com/hhvm/hsl-experimental/blob/master/src/filesystem/FileWriteMode.php) is `FileWriteMode::TRUNCATE`, which can be changed using the 2nd argument.

```hack
use type HH\Lib\Experimental\Filesystem\FileWriteMode;

...

await $file->write($content);
await $file->write($content, FileWriteMode::MUST_CREATE);
```

The previous method will truncate the file before writing to it. To append to the file instead, use `append(): Awaitable<void>`.

```hack
await $file->append('foo');
await $file->append('bar');
```

The reverse can also be used, `prepend(): Awaitable<void>`, which will write content to the beginning of the file.

```hack
await $file->prepend('foo');
await $file->prepend('bar');
```

When appending or prepending, the file resource is automatically closed.

These methods will also lock the file until the content has been written.

### Locking

We've mentioned locking previously, as it automatically occurs during reads and writes, but if you need to implement locking manually you can do so by accessing the file handle, and use the `lock` method.

You can pass the lock type as the 1st argument, which must be a value of the [`FileLockType`](https://github.com/hhvm/hsl-experimental/blob/master/src/filesystem/FileLockType.php) enum.

```hack
use type HH\Lib\Experimental\Filesystem\FileLockType;

$type = FileLockType::

await (using $write = $file->getWriteHandle($mode)) {
  using ($lock = $file->lock($type)) {
    // Do something with the write handle.
  }
}

await (using $read = $file->getReadHandle()) {
  using ($lock = $file->lock($type)) {
    // Do something with the read handle.
  }
}
```

## Folders

`Nuxed\Io\Folder`s provide management of files and folders on the filesystem.

### Reading

To gather the child nodes within a folder, the `files(): Awaitable<Contaienr<File>>` method will return a list of `File`s, and `folders(): Awaitable<Container<Folder>>` will return a list of `Folder`s. Lists can be sorted by passing `true` as the 1st argument, and gathering via recursion is also possible by passing `true` as the 2nd argument.

```hack
$files = await $folder->files(); // Container<File>
$folders = await $folder->folders(); // Container<Folder>
```

To gather a list of both files and folders, use `read()`, which accepts the same arguments.

```hack
$nodes = await $folder->read(); // Container<Node>
```

### Finding

The `find()` method will attempt to find (glob) files or folders that match a specific pattern. An optional filter can be passed as the 2nd argument to return either files or folders.

```hack
$nodes = await $folder->find('foo.*'); // Container<Node>
$files = await $folder->find('*.html', File::class); // Container<File>
```

The available filters are:

* `Node::class` - Returns both files and folders
* `File::class` - Returns only files
* `Folder::class` - Returns only folders

### Cleaning

To delete all files within the folder but not the folder itself, use `flush(): Awaitable<void>`.

```hack
await $folder->flush();
```

---

## Security Vulnerabilities

If you discover a security vulnerability within Nuxed, please send an e-mail to Saif Eddin Gmati via azjezz@protonmail.com.

---

## License

The Nuxed framework is open-sourced software licensed under the MIT-licensed.