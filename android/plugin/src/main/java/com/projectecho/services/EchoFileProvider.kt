package com.projectecho.services

import androidx.core.content.FileProvider

/** A distinct provider avoids merging with Godot's own FileProvider entry. */
class EchoFileProvider : FileProvider()
